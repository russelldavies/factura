module Client exposing (Client, decoder)

import Invoice exposing (Invoice)
import Json.Decode as Decode exposing (Decoder, field)
import Json.Decode.Pipeline exposing (hardcoded, optionalAt, requiredAt)
import Json.Encode as Encode
import Tax
import Ulid exposing (Ulid)


type alias Client =
    { clientId : Ulid
    , company : Maybe String
    , name : Maybe String
    , address : String
    , email : String
    , phone : Maybe String
    , taxNumber : Maybe Tax.TaxNumber
    , invoices : List Invoice
    }


decoder : Decoder Client
decoder =
    Decode.succeed Client
        |> requiredAt [ "ClientId", "S" ] Ulid.decode
        |> optionalAt [ "Company", "S" ] (Decode.nullable Decode.string) Nothing
        |> requiredAt [ "Name", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "Address", "S" ] Decode.string
        |> requiredAt [ "Email", "S" ] Decode.string
        |> optionalAt [ "Phone", "S" ] (Decode.nullable Decode.string) Nothing
        |> optionalAt [ "TaxNumber", "M" ] (Decode.nullable Tax.taxNumberDecoder) Nothing
        |> hardcoded []
