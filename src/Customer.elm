module Customer exposing (Customer, decoder)

import Json.Decode as Decode exposing (Decoder, field)
import Json.Decode.Pipeline exposing (requiredAt)
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
    Decode.succeed Customer
        |> requiredAt [ "CustomerId", "S" ] Ulid.decode
        |> requiredAt [ "Name", "S" ] Decode.string
        |> requiredAt [ "Address", "S" ] Decode.string
        |> requiredAt [ "Email", "S" ] Decode.string
        |> requiredAt [ "Phone", "S" ] Decode.string
        |> requiredAt [ "TaxNum", "S" ] Decode.string
