module Customer exposing (Customer, decoder, encode)

import Json.Decode as Decode exposing (Decoder, field)
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
        (field "CustomerId" <| field "S" Ulid.decode)
        (field "Name" <| field "S" Decode.string)
        (field "Address" <| field "S" Decode.string)
        (field "Email" <| field "S" Decode.string)
        (field "Phone" <| field "S" Decode.string)
        (field "TaxNum" <| field "S" Decode.string)


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
