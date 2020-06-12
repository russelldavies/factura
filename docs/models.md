# Entity Chart

Entity       | PK                                    | SK
-------------| --------------------------------------| -------------------------------------
Accounts     | ACCOUNT                               | ACCOUNT
Clients      | CLIENT#<ClientId>                     | CLIENT#<ClientId>
ClientEmails | CLIENTEMAIL#<Email>                   | CLIENTEMAIL#<Email>
Invoices     | CLIENT#<ClientId>                     | #INVOICE#<InvoiceId>
InvoiceNumber| INVOICENUMBER#<Number>                | INVOICENUMBER#<Number>
Line Items   | INVOICE#<InvoiceId>#LINEITEM#<ItemId> | INVOICE#<InvoiceId>#LINEITEM#<ItemId>

Entity     | GSI1PK              | GSI1SK
-----------| --------------------| -------------------
Invoices   | INVOICE#<InvoiceId> | INVOICE#<InvoiceId>
Line Items | INVOICE#<InvoiceId> | LINEITEM#<ItemId>

Note that the `SK` for Invoices is prefixed with a `#` as fetching is done in
descending order with the Client data desired at the beginning of results.

The Account entity is a singleton. If there were multiple accounts (if this was
a hosted service for many different users) then the PK and SK would be
`ACCOUNT#<AccountId>`.


# Access Patterns

System actions:
* Create account (condition expression to ensure uniqueness on email)

Account actions:
* Create client (condition express to ensure uniqueness on email)
* Create and update invoice, including line items (condition to express
  uniqueness on invoice number)

Client access patterns:
* Update client details
* View client details and most recent invoices for client
* View invoice and invoice line items


Access Pattern | Index | Parameters | Notes
---------------| ----- | ---------- | -----
Create client  | N/A   | N/A | Use transaction to create Client and ClientEmail item with conditions to ensure uniqueness on both
Create invoice | N/A | N/A | Use `TransactWriteItems` to create Invoice, InvoiceNumber, and LineItems in one request with conditions to ensure uniqueness on both
View client and most recent invoices | Main table | ClientId | Use `ScanIndexForward=False` to fetch in descending order
View invoice and line items | GSI1 | InvoiceId |
