module Customer exposing (Customer, decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ulid exposing (Ulid)


type alias Customer =
    { customerId : Ulid
    , name : String
    , address : String
    , email : String
    , phone : String
    , taxNum : String
    }


decoder : Decoder Customer
decoder =
    Decode.map6 Customer
        (Decode.field "CustomerId" Ulid.decode)
        (Decode.field "Name" Decode.string)
        (Decode.field "Address" Decode.string)
        (Decode.field "Email" Decode.string)
        (Decode.field "Phone" Decode.string)
        (Decode.field "TaxNum" Decode.string)


encode : Customer -> Encode.Value
encode customer =
    Encode.object
        [ ( "CustomerId", Ulid.encode customer.customerId )
        , ( "Name", Encode.string customer.name )
        , ( "Address", Encode.string customer.address )
        , ( "Email", Encode.string customer.email )
        , ( "Phone", Encode.string customer.phone )
        , ( "TaxNum", Encode.string customer.taxNum )
        ]
