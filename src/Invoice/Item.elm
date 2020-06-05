module Invoice.Item exposing (Item)

import Tax exposing (Tax)
import Ulid exposing (Ulid)


type alias Item =
    { invoiceId : Ulid
    , itemId : Ulid
    , task : String
    , rate : Float
    , hours : Float
    , discountPct : Float
    , taxes : List Tax
    }
