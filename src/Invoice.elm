module Invoice exposing (Invoice, decoder, subTotal, taxes, total)

import Dict exposing (Dict)
import Element.Font as Font
import Invoice.Customer as Customer exposing (Customer)
import Invoice.LineItem as LineItem exposing (LineItem)
import Invoice.Supplier as Supplier exposing (Supplier)
import Iso8601
import Json.Decode as Decode exposing (Decoder, field)
import Json.Decode.Extra exposing (parseInt)
import Json.Decode.Pipeline exposing (hardcoded, optionalAt, requiredAt)
import Json.Encode as Encode
import Money exposing (Currency)
import Tax
import Time exposing (Posix)
import Ulid exposing (Ulid)


type alias Invoice =
    { clientId : Ulid
    , invoiceId : Ulid
    , supplier : Supplier
    , customer : Customer
    , number : Int
    , issuedOn : Posix
    , paidOn : Maybe Posix
    , terms : String
    , notes : String
    , emailed : Bool
    , currency : Currency
    , lineItems : List LineItem
    }


subTotal : Invoice -> Float
subTotal invoice =
    invoice.lineItems
        |> List.map LineItem.total
        |> List.sum


taxes : Invoice -> List ( String, Float )
taxes invoice =
    invoice.lineItems
        |> List.map LineItem.taxes
        |> List.concat
        |> List.foldr
            (\( taxName, amount ) acc ->
                Dict.update taxName (Maybe.map ((+) amount) >> Maybe.withDefault amount >> Just) acc
            )
            Dict.empty
        |> Dict.toList


total : Invoice -> Float
total invoice =
    invoice.lineItems
        |> List.map LineItem.total
        |> List.sum


decoder : Decoder Invoice
decoder =
    Decode.succeed Invoice
        |> requiredAt [ "ClientId", "S" ] Ulid.decode
        |> requiredAt [ "InvoiceId", "S" ] Ulid.decode
        |> requiredAt [ "Supplier", "M" ] Supplier.decoder
        |> requiredAt [ "Customer", "M" ] Customer.decoder
        |> requiredAt [ "Number", "N" ] parseInt
        |> requiredAt [ "IssuedOn", "S" ] Iso8601.decoder
        |> optionalAt [ "PaidOn", "S" ] (Decode.nullable Iso8601.decoder) Nothing
        |> requiredAt [ "Terms", "S" ] Decode.string
        |> requiredAt [ "Notes", "S" ] Decode.string
        |> requiredAt [ "Emailed", "BOOL" ] Decode.bool
        |> requiredAt [ "Currency", "S" ] currencyDecoder
        |> hardcoded []


currencyDecoder : Decoder Currency
currencyDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case Money.currencyFromString s of
                    Just currency ->
                        Decode.succeed currency

                    Nothing ->
                        Decode.fail "Invalid currency"
            )
