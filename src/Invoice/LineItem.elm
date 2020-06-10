module Invoice.LineItem exposing (LineItem, decoder, taxes, total)

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


total : LineItem -> Float
total item =
    item.rate.cost * item.quantity


taxes : LineItem -> List ( String, Float )
taxes lineItem =
    lineItem.taxes
        |> List.map
            (\{ name, rate } ->
                ( name ++ " " ++ String.fromFloat (rate * 100) ++ "%"
                , rate * total lineItem
                )
            )


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
