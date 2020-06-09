module Invoice.Customer exposing (Customer, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optionalAt, requiredAt)
import Tax



-- This exists separately to other Supplier module because it's a slow changing
-- dimension.


type alias Customer =
    { company : Maybe String
    , name : Maybe String
    , address : String
    , email : String
    , phone : Maybe String
    , taxNumber : Maybe Tax.TaxNumber
    }


decoder : Decoder Customer
decoder =
    Decode.succeed Customer
        |> optionalAt [ "Company", "S" ] (Decode.nullable Decode.string) Nothing
        |> optionalAt [ "Name", "S" ] (Decode.nullable Decode.string) Nothing
        |> requiredAt [ "Address", "S" ] Decode.string
        |> requiredAt [ "Email", "S" ] Decode.string
        |> optionalAt [ "Phone", "S" ] (Decode.nullable Decode.string) Nothing
        |> optionalAt [ "TaxNumber", "M" ] (Decode.nullable Tax.taxNumberDecoder) Nothing
