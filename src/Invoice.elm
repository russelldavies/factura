module Invoice exposing (Invoice, decoder)

import Customer exposing (Customer)
import Date exposing (Date)
import Invoice.Item as Item exposing (Item)
import Json.Decode as Decode exposing (Decoder, field)
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


decoder : Decoder Invoice
decoder =
    Decode.succeed Invoice
        |> requiredAt [ "InvoiceId", "S" ] Ulid.decode
        |> requiredAt [ "supplier", "M" ] Supplier.decoder
        |> requiredAt [ "customer", "M" ] Customer.decoder
        |> requiredAt [ "number", "N" ] Decode.string
        |> requiredAt [ "IssuedAt", "S" ] dateDecoder
        |> requiredAt [ "Term", "S" ] Decode.string
        |> requiredAt [ "Notes", "S" ] Decode.string
        |> requiredAt [ "Emailed", "BOOL" ] Decode.bool
        |> requiredAt [ "Paid", "BOOL" ] Decode.bool
        |> hardcoded []


encode : Invoice -> Encode.Value
encode invoice =
    Encode.object
        [ ( "InvoiceId", Ulid.encode invoice.invoiceId )
        , ( "Supplier", Supplier.encode invoice.supplier )
        , ( "Customer", Customer.encode invoice.customer )
        , ( "IssuedAt", Encode.string (Date.toIsoString invoice.issuedAt) )
        , ( "Terms", Encode.string invoice.terms )
        , ( "Notes", Encode.string invoice.notes )
        , ( "Emailed", Encode.bool invoice.emailed )
        , ( "Paid", Encode.bool invoice.paid )
        ]


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
