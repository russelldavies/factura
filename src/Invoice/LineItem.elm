module Invoice.LineItem exposing (LineItem, decoder, subTotal, total)

import Json.Decode as Decode exposing (Decoder, field)
import Json.Decode.Extra exposing (parseFloat)
import Json.Decode.Pipeline exposing (hardcoded, requiredAt)
import Tax exposing (Tax)
import Ulid exposing (Ulid)


type alias LineItem =
    { invoiceId : Ulid
    , lineItemId : Ulid
    , description : String
    , rate : Rate
    , quantity : Float
    , discountPct : Float
    , taxes : List Tax
    }


type alias Rate =
    { cost : Float
    , unit : String
    }


subTotal : LineItem -> Float
subTotal item =
    item.rate.cost * item.quantity


total : LineItem -> Float
total item =
    item.taxes
        |> List.map (\tax -> (1 + tax.rate) * subTotal item)
        |> List.sum


decoder : Decoder LineItem
decoder =
    Decode.succeed LineItem
        |> requiredAt [ "InvoiceId", "S" ] Ulid.decode
        |> requiredAt [ "LineItemId", "S" ] Ulid.decode
        |> requiredAt [ "Description", "S" ] Decode.string
        |> requiredAt [ "Rate", "M" ] rateDecoder
        |> requiredAt [ "Quantity", "N" ] parseFloat
        |> requiredAt [ "DiscountPct", "N" ] parseFloat
        |> requiredAt [ "Taxes", "L" ] (Decode.list (Decode.field "M" Tax.taxDecoder))


rateDecoder : Decoder Rate
rateDecoder =
    Decode.map2 Rate
        (Decode.at [ "Cost", "N" ] parseFloat)
        (Decode.at [ "Unit", "S" ] Decode.string)
