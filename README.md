# factura

A simple invoicing system that I wrote for my own invoicing needs. No fancy
features, just lets my clients view their invoices (and I get to be in full
control of the data).

It's an Elm single-page app (SPA) that uses AWS DynamoDB as the datastore. The
SPA queries the DynamoDB HTTP JSON API directly (with a very restricted IAM
policy) so no API backend is required.
