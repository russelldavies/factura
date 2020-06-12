module Account exposing (Account, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra exposing (parseInt)
import Json.Decode.Pipeline exposing (requiredAt)
import Set exposing (Set)
import Tax
import Ulid exposing (Ulid)


type alias Account =
    { company : Maybe String
    , name : Maybe String
    , address : String
    , email : String
    , phone : Maybe String
    , taxNumber : Tax.TaxNumber
    , lastInvoiceNumber : Int
    , clients : List Ulid
    }


decoder : Decoder Account
decoder =
    Decode.succeed Account
        |> requiredAt [ "Company", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "Name", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "Address", "S" ] Decode.string
        |> requiredAt [ "Email", "S" ] Decode.string
        |> requiredAt [ "Phone", "S" ] (Decode.nullable Decode.string)
        |> requiredAt [ "TaxNumber", "M" ] Tax.taxNumberDecoder
        |> requiredAt [ "LastInvoiceNumber", "N" ] parseInt
        |> requiredAt [ "Clients", "SS" ] (Decode.list Ulid.decode)
