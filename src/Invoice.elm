module Invoice exposing (Invoice, decoder, subTotal, total)

import Customer exposing (Customer)
import Date exposing (Date)
import Invoice.Item as Item exposing (Item)
import Json.Decode as Decode exposing (Decoder, field)
import Json.Decode.Extra exposing (parseInt)
import Json.Decode.Pipeline exposing (hardcoded, requiredAt)
import Json.Encode as Encode
import Supplier exposing (Supplier)
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
    , paid : Bool
    , items : List Item
    }


total : Invoice -> Float
total invoice =
    List.map Item.subTotal invoice.items
        |> List.sum


subTotal : Invoice -> Float
subTotal invoice =
    List.map Item.total invoice.items
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
        |> requiredAt [ "Paid", "BOOL" ] Decode.bool
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
