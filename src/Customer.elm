module Customer exposing (Customer)

import Ulid exposing (Ulid)


type alias Customer =
    { customerId : Ulid
    , name : String
    , address : String
    , email : String
    , phone : String
    , taxNum : String
    }
