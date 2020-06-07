module Supplier exposing (Supplier, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (requiredAt)
import Json.Encode as Encode
import Ulid exposing (Ulid)


type alias Supplier =
    { supplierId : Ulid
    , name : String
    , address : String
    , email : String
    , phone : String
    , regNum : String
    }


decoder : Decoder Supplier
decoder =
    Decode.succeed Supplier
        |> requiredAt [ "SupplierId", "S" ] Ulid.decode
        |> requiredAt [ "Name", "S" ] Decode.string
        |> requiredAt [ "Address", "S" ] Decode.string
        |> requiredAt [ "Email", "S" ] Decode.string
        |> requiredAt [ "Phone", "S" ] Decode.string
        |> requiredAt [ "RegNum", "S" ] Decode.string
