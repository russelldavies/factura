module Supplier exposing (Supplier)

import Ulid exposing (Ulid)


type alias Supplier =
    { supplierId : Ulid
    , name : String
    , address : String
    , email : String
    , phone : String
    , registrationNum : String
    }
