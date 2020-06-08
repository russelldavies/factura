import boto3
import ulid
from ulid import ULID
from datetime import datetime
import yaml
import csv



def load(filename):
    with open('./import/data.yaml') as f:
        data = yaml.safe_load(f)
    for customer in data['customers']:
        customer_id = create_customer(customer)
        # Build invoice item
        for invoice in data['invoices'][customer['email']]:
            invoice_id = create_invoice(customer_id, {
                'supplier': invoice['supplier'],
                'customer': invoice['customer'],
                'number': invoice['number'],
                'issued_at': invoice['issued_at'],
                'terms': invoice['terms'],
                'notes': invoice['notes'],
                'emailed': True,
                'paid_on': str(invoice['paid_on']),
                'currency': 'eur',
            })
            line_items = read_line_items(invoice['vat'], invoice['number'])
            for line_item in line_items:
                line_item['invoice_id'] = str(invoice_id)
                create_line_item(invoice['issued_at'], line_item)
            print('Created invoice {}'.format(invoice['number']))



def read_line_items(vat_rate, invoice_num):
    line_items = []
    with open(f'./import/{invoice_num}.csv', 'r') as f:
        csvreader = csv.reader(f, delimiter='\t')
        for row in csvreader:
            line_items.append({
                'description': row[1],
                'rate': float(row[2]),
                'hours': float(row[3]),
                'discount_pct': 0,
                'taxes': [{'name': 'VAT', 'rate': vat_rate}],
            })
    return line_items



# DyanmoDB funcs

table_name = 'Factura'
client = boto3.client('dynamodb')


def create_customer(record, date=None):
    item_id = ULID.from_datetime(datetime.strptime(date, '%Y-%m-%d')) if date else ULID()
    item_type = 'Customer'
    pk = '{}#{}'.format(item_type.upper(), item_id)
    sk = pk

    item = {
        **dict_to_item({
            'PK': pk,
            'SK': sk,
            'Type': item_type,
            f'{item_type}Id': str(item_id),
        }, False),
        **dict_to_item(record),
    }

    client.transact_write_items(
        TransactItems=[
            {
                'Put': {
                    'TableName': table_name,
                    'Item': item,
                    #'ConditionExpression': 'attribute_not_exists(PK)'
                },
            },
            {
                'Put': {
                    'TableName': table_name,
                    'Item': {
                        'PK': { 'S': '{}EMAIL#{}'.format(item_type.upper(), record['email']) },
                        'SK': { 'S': '{}EMAIL#{}'.format(item_type.upper(), record['email']) },
                    },
                    #'ConditionExpression': 'attribute_not_exists(PK)'
                },
            },
        ]
    )
    return item_id


def create_invoice(customer_id, invoice):
    issued_at = datetime.combine(invoice['issued_at'], datetime.min.time())
    invoice['issued_at'] = str(invoice['issued_at'])
    item_type = 'Invoice'

    invoice_id = ULID.from_datetime(issued_at)
    pk = 'CUSTOMER#{}'.format(customer_id)
    sk = 'INVOICE#{}'.format(invoice_id)
    gsi1pk = sk
    gsi1sk = sk
    item = {
        **dict_to_item({
            'PK': pk,
            'SK': sk,
            'GSI1PK': gsi1pk,
            'GSI1SK': gsi1sk,
            'Type': item_type,
            'InvoiceId': str(invoice_id),
        }, False),
        **dict_to_item(invoice),
    }
    client.put_item(
        TableName=table_name,
        Item=item,
    )
    return invoice_id


def create_line_item(issued_at, line_item):
    line_item_id = ULID.from_datetime(datetime.combine(issued_at, datetime.min.time()))
    item_type = 'LineItem'
    pk = 'INVOICE#{}#LINEITEM#{}'.format(line_item['invoice_id'], line_item_id)
    sk = pk
    gsi1pk = 'INVOICE#{}'.format(line_item['invoice_id'])
    gsi1sk = f'LINEITEM#{line_item_id}'
    item = {
        **dict_to_item({
            'PK': pk,
            'SK': sk,
            'GSI1PK': gsi1pk,
            'GSI1SK': gsi1sk,
            'Type': item_type,
            'LineItemId': str(line_item_id),
        }, False),
        **dict_to_item(line_item),
    }
    client.put_item(
        TableName=table_name,
        Item=item,
    )
    return line_item_id



def dict_to_item(d, camel=True):
    return {snake_to_camel(key) if camel else key: ddb_json(val) for key, val in d.items()}


def ddb_json(val):
    if type(val) is str:
        return {'S': val}
    elif type(val) in (int, float):
        return {'N': str(val)}
    elif val is None:
        return {'NULL': True}
    elif type(val) is dict:
        return {'M': {snake_to_camel(key): ddb_json(val) for key, val in val.items()}}
    elif type(val) is list:
        return {'L': [ddb_json(_) for _ in val]}
    elif type(val) is bool:
        return {'BOOL': val}


def snake_to_camel(s):
    return ''.join(map(str.title, s.split('_')))
