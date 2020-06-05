module Supplier exposing (Supplier, decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ulid exposing (Ulid)


type alias Supplier =
    { supplierId : Ulid
    , name : String
    , address : String
    , email : String
    , phone : String
    , registrationNum : String
    }


decoder : Decoder Supplier
decoder =
    Decode.map6 Supplier
        (Decode.field "SupplierId" Ulid.decode)
        (Decode.field "Name" Decode.string)
        (Decode.field "Address" Decode.string)
        (Decode.field "Email" Decode.string)
        (Decode.field "Phone" Decode.string)
        (Decode.field "RegistrationNum" Decode.string)


encode : Supplier -> Encode.Value
encode supplier =
    Encode.object
        [ ( "SupplierId", Ulid.encode supplier.supplierId )
        , ( "Name", Encode.string supplier.name )
        , ( "Address", Encode.string supplier.address )
        , ( "Email", Encode.string supplier.email )
        , ( "Phone", Encode.string supplier.phone )
        , ( "RegistrationNum", Encode.string supplier.registrationNum )
        ]
