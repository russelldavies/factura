module Supplier exposing (Supplier, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (requiredAt)
import Json.Encode as Encode
import Tax
import Ulid exposing (Ulid)


type alias Supplier =
    { supplierId : Ulid
    , company : Maybe String
    , name : Maybe String
    , address : String
    , email : String
    , phone : Maybe String
    , taxNumber : Tax.TaxNumber
    }


decoder : Decoder Supplier
decoder =
    Decode.succeed Supplier
        |> requiredAt [ "SupplierId", "S" ] Ulid.decode
        |> requiredAt [ "Company", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "Name", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "Address", "S" ] Decode.string
        |> requiredAt [ "Email", "S" ] Decode.string
        |> requiredAt [ "Phone", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "TaxNumber", "M" ] Tax.taxNumberDecoder
