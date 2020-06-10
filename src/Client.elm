module Client exposing (Client, decoder)

import Json.Decode as Decode exposing (Decoder, field)
import Json.Decode.Pipeline exposing (requiredAt)
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
    }


decoder : Decoder Client
decoder =
    Decode.succeed Client
        |> requiredAt [ "ClientId", "S" ] Ulid.decode
        |> requiredAt [ "Company", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "Name", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "Address", "S" ] Decode.string
        |> requiredAt [ "Email", "S" ] Decode.string
        |> requiredAt [ "Phone", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "TaxNumber", "M" ] (Decode.nullable Tax.taxNumberDecoder)
