module Invoice exposing (Invoice)

import Customer exposing (Customer)
import Date exposing (Date)
import Supplier exposing (Supplier)
import Ulid exposing (Ulid)


type alias Invoice =
    { invoiceId : Ulid
    , supplier : Supplier
    , customer : Customer
    , issuedAt : Date
    , terms : String
    , notes : String
    , emailed : Bool
    , paid : Bool
    }
