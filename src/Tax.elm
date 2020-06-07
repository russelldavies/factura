module Tax exposing (Tax, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra exposing (parseFloat)
import Json.Decode.Pipeline exposing (requiredAt)


type alias Tax =
    { name : String
    , rate : Float
    }


decoder : Decoder Tax
decoder =
    Decode.succeed Tax
        |> requiredAt [ "Name", "S" ] Decode.string
        |> requiredAt [ "Rate", "N" ] parseFloat
