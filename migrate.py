from datetime import datetime
import yaml
import csv

import admin


def load():
    with open('./import/data.yaml') as f:
        import_data = yaml.safe_load(f)

    admin.create_account(import_data['account'])
    clients = {}
    for client_key, client_details in import_data['clients'].items():
        clients[client_key] = admin.create_client(client_details)
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


def create_invoice(client_id, supplier, customer, row):
    return admin.create_invoice(client_id, {
        'number': int(row['invoice_number']),
        'supplier': supplier,
        'customer': customer,
        'issued_on': datetime.strptime(row['create_date'], "%Y-%m-%d"),
        'paid_on': datetime.strptime(row['date_paid'], "%Y-%m-%d"),
        'terms': row['terms'].replace('\\n', '\n'),
        'notes': row['notes'],
        'emailed': True,
        'currency': 'eur',
    })


def create_line_item(invoice_id, invoice_row, row):
    return admin.create_line_item(invoice_id, {
        'description': row[1],
        'rate': {'cost': float(row[2].replace(',', '')), 'unit': 'hour'},
        'quantity': float(row[3].replace(',', '')),
        'discount_pct': 0,
        'taxes': [{'name': 'VAT', 'rate': float(invoice_row['vat'])}],
    })


if __name__ == '__main__':
    load()
