module Invoice exposing (Invoice)

import Customer exposing (Customer)
import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Supplier exposing (Supplier)
import Ulid exposing (Ulid)


type alias Invoice =
    { invoiceId : Ulid
    , supplier : Supplier
    , customer : Customer
    , issuedAt : Date
    , terms : String
    , notes : String
    , emailed : Bool
    , paid : Bool
    }


decoder : Decoder Invoice
decoder =
    Decode.map8 Invoice
        (Decode.field "InvoiceId" Ulid.decode)
        (Decode.field "supplier" Supplier.decoder)
        (Decode.field "customer" Customer.decoder)
        (Decode.field "IssuedAt" dateDecoder)
        (Decode.field "Term" Decode.string)
        (Decode.field "Notes" Decode.string)
        (Decode.field "Emailed" Decode.bool)
        (Decode.field "Paid" Decode.bool)


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
