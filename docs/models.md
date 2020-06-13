# Entity Chart

Entity       | PK                                       | SK
-------------| --------------------------------------   | -------------------------------------
Accounts     | ACCOUNT<AccountId>                       | ACCOUNT<AccountId>
AccountEmails| ACCOUNTEMAIL#<Email>                     | ACCOUNTEMAIL#<Email>
Clients      | CLIENT#<ClientId>                        | CLIENT#<ClientId>
ClientEmails | ACCOUNT<AccountId>#CLIENTEMAIL#<Email>   | ACCOUNT<AccountId>#CLIENTEMAIL#<Email>
Invoices     | CLIENT#<ClientId>                        | #INVOICE#<InvoiceId>
InvoiceNumber| ACCOUNT<AccountId>#INVOICENUMBER#<Number>| ACCOUNT<AccountId>#INVOICENUMBER#<Number>
Line Items   | INVOICE#<InvoiceId>#LINEITEM#<ItemId>    | INVOICE#<InvoiceId>#LINEITEM#<ItemId>

Entity     | GSI1PK              | GSI1SK
-----------| --------------------| -------------------
Invoices   | INVOICE#<InvoiceId> | INVOICE#<InvoiceId>
Line Items | INVOICE#<InvoiceId> | LINEITEM#<ItemId>

Note that the `SK` for Invoices is prefixed with a `#` as fetching is done in
descending order with the Client data desired at the beginning of results.


# Access Patterns

Access Pattern | Index | Parameters | Notes
---------------| ----- | ---------- | -----
Create account | N/A | N/A | Condition expression to ensure uniqueness on email.
View account | N/A | N/A |
Create client  | N/A | N/A | Use a transaction to create Client and ClientEmail item with conditions to ensure uniqueness on both.
View clients | N/A | `AccountId` |
Create invoice | N/A | N/A | Use a transaction to create Invoice, InvoiceNumber, and LineItems in one request with conditions to ensure uniqueness on both.
View client and most recent invoices | Main table | `ClientId` | Fetch in descending order.
View invoice and line items | GSI1 | `InvoiceId` |
