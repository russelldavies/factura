module Tax exposing (Tax, TaxNumber, taxDecoder, taxNumberDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra exposing (parseFloat)
import Json.Decode.Pipeline exposing (requiredAt)


type alias Tax =
    { name : String
    , rate : Float
    }


type alias TaxNumber =
    { name : String
    , number : String
    }


taxDecoder : Decoder Tax
taxDecoder =
    Decode.succeed Tax
        |> requiredAt [ "Name", "S" ] Decode.string
        |> requiredAt [ "Rate", "N" ] parseFloat


taxNumberDecoder : Decoder TaxNumber
taxNumberDecoder =
    Decode.succeed TaxNumber
        |> requiredAt [ "Name", "S" ] Decode.string
        |> requiredAt [ "Number", "S" ] Decode.string
