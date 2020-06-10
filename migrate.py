import boto3
import ulid
from ulid import ULID
import time
from datetime import datetime
import yaml
import csv


def load():
    with open('./import/data.yaml') as f:
        import_data = yaml.safe_load(f)

    clients = {}
    for client_key, client_details in import_data['clients'].items():
        clients[client_key] = create_client(client_details)
        print(f'Created client {client_key}')

    with open('import/invoices.csv', 'r') as f:
        csvreader = csv.DictReader(f)
        for row in csvreader:
            client_key = import_data['customer_clients'][row['customer']]
            client_id = clients[client_key]
            supplier = import_data['suppliers'][row['supplier']]
            customer = import_data['customers'][row['customer']]
            invoice_id = create_invoice(client_id, supplier, customer, row)
            line_items = process_line_items(invoice_id, row)
            print('Created invoice ', invoice_id)


def process_line_items(invoice_id, invoice_row):
    invoice_num = invoice_row['invoice_number']
    with open(f'./import/{invoice_num}.csv', 'r') as f:
        csvreader = csv.reader(f, delimiter='\t')
        for row in csvreader:
            create_line_item(invoice_id, invoice_row, row)


# DyanmoDB funcs

table_name = 'Factura'
client = boto3.client('dynamodb')


def create_client(record):
    company = record.get('company')
    name = record.get('name')
    address = record.get('address')
    email = record.get('email')
    phone = record.get('phone')

    client_id = ULID()
    item_type = 'Client'
    pk = '{}#{}'.format(item_type.upper(), client_id)
    sk = pk

    item = dict_to_item({
        'PK': pk,
        'SK': sk,
        'Type': item_type,

        'ClientId': str(client_id),
        'Company': company,
        'Name': name,
        'Address': address,
        'Email': email,
        'Phone': phone,
    })

    client.transact_write_items(
        TransactItems=[
            {
                'Put': {
                    'TableName': table_name,
                    'Item': item,
                    'ConditionExpression': 'attribute_not_exists(PK)'
                },
            },
            #{
            #    'Put': {
            #        'TableName': table_name,
            #        'Item': {
            #            'PK': { 'S': '{}EMAIL#{}'.format(item_type.upper(), record['email']) },
            #            'SK': { 'S': '{}EMAIL#{}'.format(item_type.upper(), record['email']) },
            #        },
            #        'ConditionExpression': 'attribute_not_exists(PK)'
            #    },
            #},
        ]
    )
    return client_id


def create_invoice(client_id, supplier, customer, row):
    invoice_number = int(row['invoice_number'])
    issued_on = datetime.strptime(row['create_date'], "%Y-%m-%d")
    paid_on = datetime.strptime(row['date_paid'], "%Y-%m-%d")
    terms = row['terms'].replace('\\n', '\n')
    notes = row['notes']

    invoice_id = ULID.from_datetime(issued_on)
    item_type = 'Invoice'
    pk = f'CLIENT#{client_id}'
    sk = f'INVOICE#{invoice_id}'
    gsi1pk = sk
    gsi1sk = sk

    item = dict_to_item({
        'PK': pk,
        'SK': sk,
        'GSI1PK': gsi1pk,
        'GSI1SK': gsi1sk,
        'Type': item_type,

        'ClientId': str(client_id),
        'InvoiceId': str(invoice_id),
        'Supplier': rekey_map(supplier),
        'Customer': rekey_map(customer),
        'Number': invoice_number,
        'IssuedOn': issued_on.isoformat(),
        'PaidOn': paid_on.isoformat(),
        'Terms': terms,
        'Notes': notes,
        'Emailed': True,
        'Currency': 'eur',
    })

    client.transact_write_items(
        TransactItems=[
            {
                'Put': {
                    'TableName': table_name,
                    'Item': item,
                    'ConditionExpression': 'attribute_not_exists(PK)'
                },
            },
            #{
            #    'Put': {
            #        'TableName': table_name,
            #        'Item': {
            #            'PK': { 'S': '{}NUMBER#{}'.format(item_type.upper(), invoice['number']) },
            #            'SK': { 'S': '{}NUMBER#{}'.format(item_type.upper(), invoice['number']) },
            #        },
            #        'ConditionExpression': 'attribute_not_exists(PK)'
            #    },
            #},
        ]
    )
    return invoice_id


def create_line_item(invoice_id, invoice_row, row):
    description = row[1]
    rate = rekey_map({'cost': float(row[2].replace(',', '')), 'unit': 'hour'})
    quantity = float(row[3].replace(',', ''))
    discount_pct = 0
    taxes = rekey_map([{'name': 'VAT', 'rate': float(invoice_row['vat'])}])

    line_item_id = ULID()
    item_type = 'LineItem'
    pk = f'INVOICE#{invoice_id}#LINEITEM#{line_item_id}'
    sk = pk
    gsi1pk = f'INVOICE#{invoice_id}'
    gsi1sk = f'LINEITEM#{line_item_id}'

    item = dict_to_item({
        'PK': pk,
        'SK': sk,
        'GSI1PK': gsi1pk,
        'GSI1SK': gsi1sk,
        'Type': item_type,

        'InvoiceId': str(invoice_id),
        'LineItemId': str(line_item_id),
        'Description': description,
        'Rate': rate,
        'Quantity': quantity,
        'DiscountPct': discount_pct,
        'Taxes': taxes,
    })

    client.put_item(
        TableName=table_name,
        Item=item,
    )
    return line_item_id


# Helpers

def dict_to_item(d):
    return {key: ddb_json(val) for key, val in d.items() if val != None}


def ddb_json(val):
    if type(val) is str:
        return {'S': val}
    elif type(val) in (int, float):
        return {'N': str(val)}
    elif val is None:
        return {'NULL': True}
    elif type(val) is dict:
        return {'M': {key: ddb_json(val) for key, val in val.items()}}
    elif type(val) is list:
        return {'L': [ddb_json(_) for _ in val]}
    elif type(val) is bool:
        return {'BOOL': val}
    else:
        raise Exception('unsupported type')


def rekey_map(obj):
    return change_keys(obj, snake_to_camel)


def change_keys(obj, convert):
    """
    Recursively goes through the dictionary obj and replaces keys with the convert function.
    """
    if isinstance(obj, (str, int, float)):
        return obj
    if isinstance(obj, dict):
        new = obj.__class__()
        for k, v in obj.items():
            new[convert(k)] = change_keys(v, convert)
    elif isinstance(obj, (list, set, tuple)):
        new = obj.__class__(change_keys(v, convert) for v in obj)
    else:
        return obj
    return new


def snake_to_camel(s):
    return ''.join(map(str.title, s.split('_')))


if __name__ == '__main__':
    load()
