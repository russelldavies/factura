module Invoice exposing (Invoice, decoder, subTotal, total)

import Date exposing (Date)
import Invoice.Customer as Customer exposing (Customer)
import Invoice.LineItem as Item exposing (LineItem)
import Invoice.Supplier as Supplier exposing (Supplier)
import Json.Decode as Decode exposing (Decoder, field)
import Json.Decode.Extra exposing (parseInt)
import Json.Decode.Pipeline exposing (hardcoded, requiredAt)
import Json.Encode as Encode
import Money exposing (Currency)
import Tax
import Ulid exposing (Ulid)


type alias Invoice =
    { invoiceId : Ulid
    , supplier : Supplier
    , customer : Customer
    , number : String
    , issuedAt : Date
    , terms : String
    , notes : String
    , emailed : Bool
    , paidOn : Date
    , currency : Currency
    , lineItems : List LineItem
    }


total : Invoice -> Float
total invoice =
    List.map Item.subTotal invoice.lineItems
        |> List.sum


subTotal : Invoice -> Float
subTotal invoice =
    List.map Item.total invoice.lineItems
        |> List.sum


decoder : Decoder Invoice
decoder =
    Decode.succeed Invoice
        |> requiredAt [ "InvoiceId", "S" ] Ulid.decode
        |> requiredAt [ "Supplier", "M" ] Supplier.decoder
        |> requiredAt [ "Customer", "M" ] Customer.decoder
        |> requiredAt [ "Number", "N" ] Decode.string
        |> requiredAt [ "IssuedAt", "S" ] dateDecoder
        |> requiredAt [ "Terms", "S" ] Decode.string
        |> requiredAt [ "Notes", "S" ] Decode.string
        |> requiredAt [ "Emailed", "BOOL" ] Decode.bool
        |> requiredAt [ "PaidOn", "S" ] dateDecoder
        |> requiredAt [ "Currency", "S" ] currencyDecoder
        |> hardcoded []


dateDecoder : Decoder Date
dateDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case Date.fromIsoString s of
                    Ok date ->
                        Decode.succeed date

                    Err err ->
                        Decode.fail err
            )


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
