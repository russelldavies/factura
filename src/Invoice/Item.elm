module Invoice.Item exposing (Item, decoder)

import Json.Decode as Decode exposing (Decoder, field)
import Json.Decode.Extra exposing (parseFloat)
import Json.Decode.Pipeline exposing (hardcoded, requiredAt)
import Tax exposing (Tax)
import Ulid exposing (Ulid)


type alias Item =
    { itemId : Ulid
    , task : String
    , rate : Float
    , hours : Float
    , discountPct : Float
    , taxes : List Tax
    }


decoder : Decoder Item
decoder =
    Decode.succeed Item
        |> requiredAt [ "ItemId", "S" ] Ulid.decode
        |> requiredAt [ "Task", "S" ] Decode.string
        |> requiredAt [ "Rate", "N" ] parseFloat
        |> requiredAt [ "Hours", "N" ] parseFloat
        |> requiredAt [ "DiscountPct", "N" ] parseFloat
        |> requiredAt [ "Taxes", "L" ] (Decode.list (Decode.field "M" Tax.decoder))
