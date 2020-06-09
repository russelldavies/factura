module Invoice.Supplier exposing (Supplier, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (hardcoded, optionalAt, requiredAt)
import Tax



-- This exists separately to other Supplier module because it's a slow changing
-- dimension.


type alias Supplier =
    { company : Maybe String
    , name : Maybe String
    , address : String
    , email : String
    , phone : Maybe String
    , taxNumber : Tax.TaxNumber
    }


decoder : Decoder Supplier
decoder =
    Decode.succeed Supplier
        |> optionalAt [ "Company", "S" ] (Decode.nullable Decode.string) Nothing
        |> optionalAt [ "Name", "S" ] (Decode.nullable Decode.string) Nothing
        |> requiredAt [ "Address", "S" ] Decode.string
        |> requiredAt [ "Email", "S" ] Decode.string
        |> requiredAt [ "Phone", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "TaxNumber", "M" ] Tax.taxNumberDecoder
