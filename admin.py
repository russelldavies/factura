from ulid import ULID
import boto3
import datetime
import os
import yaml


table_name = os.environ['TABLE_NAME']
ddb_client = boto3.client('dynamodb')


def new_invoice():
    with open('invoice.yaml') as f:
        data = yaml.safe_load(f)
        invoice_id = create_invoice(data['account_id'], data['client_id'], data['invoice'])
        for line_item in data['line_items']:
            create_line_item(invoice_id, line_item)
        return invoice_id


def create_account(account):
    account['account_id'] = str(ULID())
    account_item = {
        **make_indexes('Account', PK=f'ACCOUNT#{account["account_id"]}',
                       SK=f'ACCOUNT#{account["account_id"]}'),
        **dict_to_item(account)
    }
    ddb_client.transact_write_items(
        TransactItems=[
            make_put_unique(account_item),
            make_put_unique(dict_to_item({
                'PK': f'ACCOUNTEMAIL#{account["email"]}',
                'SK': f'ACCOUNTEMAIL#{account["email"]}',
            }, False)),
        ]
    )
    return account['account_id']


def create_client(account_id, client):
    client['client_id'] = str(ULID())
    client_item = {
        **make_indexes('Client', PK=f'CLIENT#{client["client_id"]}',
                       SK=f'CLIENT#{client["client_id"]}'),
        **dict_to_item(client)
    }
    ddb_client.transact_write_items(
        TransactItems=[
            make_put_unique(client_item),
            make_put_unique(dict_to_item({
                'PK': f'ACCOUNT#{account_id}#CLIENTEMAIL#{client["email"]}',
                'SK': f'ACCOUNT#{account_id}#CLIENTEMAIL#{client["email"]}',
            }, False)),
            {
                'Update': {
                    'TableName': table_name,
                    'Key': dict_to_item({
                        'PK': f'ACCOUNT#{account_id}',
                        'SK': f'ACCOUNT#{account_id}',
                    }, False),
                    'UpdateExpression': 'ADD Clients :clientId',
                    'ExpressionAttributeValues': dict_to_item({
                        ':clientId': set([client['client_id']]),
                    }, False),
                }
            },
        ]
    )
    return client['client_id']


def create_invoice(account_id, client_id, invoice):
    if not invoice.get('number'):
        invoice['number'] = next_invoice_num(account_id)
    invoice_id = str(ULID.from_datetime(invoice['issued_on']))
    invoice['invoice_id'] = invoice_id
    invoice['client_id'] = client_id

    invoice_item = {
        **make_indexes('Invoice',
            PK=f'CLIENT#{client_id}',
            SK=f'#INVOICE#{invoice_id}',
            GSI1PK=f'INVOICE#{invoice_id}',
            GSI1SK=f'INVOICE#{invoice_id}',
        ),
        **dict_to_item(invoice)
    }
    ddb_client.transact_write_items(
        TransactItems=[
            make_put_unique(invoice_item),
            make_put_unique(dict_to_item({
                'PK': f'ACCOUNT#{account_id}#INVOICENUMBER#{invoice["number"]}',
                'SK': f'ACCOUNT#{account_id}#INVOICENUMBER#{invoice["number"]}',
            }, False)),
        ]
    )
    return invoice_id

def create_line_item(invoice_id, line_item):
    line_item_id = str(ULID())
    line_item['line_item_id'] = line_item_id
    line_item['invoice_id'] = invoice_id

    ddb_client.put_item(
        TableName=table_name,
        Item={
            **make_indexes('LineItem',
                PK=f'INVOICE#{invoice_id}#LINEITEM#{line_item_id}',
                SK=f'INVOICE#{invoice_id}#LINEITEM#{line_item_id}',
                GSI1PK=f'INVOICE#{invoice_id}',
                GSI1SK=f'LINEITEM#{line_item_id}',
            ),
            **dict_to_item(line_item)
        }
    )
    return line_item_id


def next_invoice_num(account_id):
    resp = ddb_client.update_item(
        TableName=table_name,
        Key=dict_to_item({
            'PK': f'ACCOUNT#{account_id}',
            'SK': f'ACCOUNT#{account_id}',
        }, False),
        UpdateExpression='SET LastInvoiceNumber = LastInvoiceNumber + :num',
        ExpressionAttributeValues=dict_to_item({ ':num': 1 }, False),
        ReturnValues='UPDATED_NEW'
    )
    return int(resp['Attributes']['LastInvoiceNumber']['N'])


# Helpers

def make_indexes(type_, **kwargs):
    kwargs['Type'] = type_
    return {key: ddb_json(val) for key, val in kwargs.items()}


def make_put_unique(item):
    return {
        'Put': {
            'TableName': table_name,
            'Item': item,
            'ConditionExpression': 'attribute_not_exists(PK)'
        }
    }


def dict_to_item(d, rekey=True):
    if rekey:
        return {key: ddb_json(val) for key, val in rekey_map(d).items() if val != None}
    else:
        return {key: ddb_json(val) for key, val in d.items() if val != None}


def ddb_json(val):
    if type(val) is str:
        return {'S': val.strip()}
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
    elif type(val) is set:
        return {'SS': list(val)}
    elif type(val) is datetime.datetime:
        return {'S': val.isoformat()}
    else:
        raise Exception('unsupported type')


def rekey_map(obj):
    snake_to_camel = lambda s: ''.join(map(str.title, s.split('_')))
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
