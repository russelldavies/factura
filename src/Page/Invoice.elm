module Page.Invoice exposing (Model, Msg, init, update, view)

import Api
import Date
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Http
import Invoice exposing (Invoice)
import Invoice.Item as Item exposing (Item)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as Encode
import Page
import RemoteData exposing (RemoteData(..), WebData)
import Result.Extra exposing (combine)
import Task exposing (Task)
import Ulid exposing (Ulid)



-- MODEL --


type alias Model =
    WebData Invoice


init : Ulid -> ( Model, Cmd Msg )
init invoiceId =
    ( RemoteData.Loading
    , Task.attempt (RemoteData.fromResult >> InvoiceResponse) (fetchInvoices invoiceId)
    )



-- UPDATE --


type Msg
    = NoOp
    | InvoiceResponse (WebData Invoice)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        InvoiceResponse response ->
            ( response, Cmd.none )



-- VIEW --


view : Model -> Page.Document Msg
view model =
    { title = "Invoice"
    , content =
        case model of
            NotAsked ->
                text "Initialising..."

            Loading ->
                text "Loading..."

            Failure err ->
                text "Something failed."

            Success invoice ->
                viewInvoice invoice
    }


viewInvoice : Invoice -> Element msg
viewInvoice invoice =
    column [ width fill ]
        [ row [ Font.size 24, Font.heavy, spacing 5 ]
            [ text "Invoice:"
            , text <| String.padLeft 7 '0' invoice.number
            ]
        , column
            [ Border.solid
            , Border.width 1
            , padding 10
            , width fill
            , spacing 20
            ]
            [ viewSupplier invoice.supplier
            , row [ paddingXY 0 50, width fill ]
                [ viewCustomer invoice.customer
                , el [ alignRight ] <| viewInvoiceDetails invoice
                ]
            , viewItemDetails invoice.items
            , viewInvoiceAmounts invoice
            , viewTerms invoice.terms
            ]
        ]


viewItemDetails items =
    let
        header =
            el
                [ Background.color (rgb 0.9 0.9 0.9)
                , Font.heavy
                ]
                << text
    in
    table []
        { data = items
        , columns =
            [ { header = header "Task"
              , width = fill
              , view = .task >> text
              }
            , { header = header "Rate"
              , width = fill
              , view = .rate >> String.fromFloat >> text
              }
            , { header = header "Hours"
              , width = fill
              , view = .hours >> String.fromFloat >> text
              }
            , { header = header "Sub Total"
              , width = fill
              , view = Item.subTotal >> String.fromFloat >> text
              }
            , { header = header "Total"
              , width = fill
              , view = Item.total >> String.fromFloat >> text
              }
            ]
        }


viewInvoiceDetails invoice =
    column []
        [ row []
            [ text "Invoice #"
            , text <| String.padLeft 7 '0' invoice.number
            ]
        , row []
            [ text "Invoice Date"
            , text <| Date.toIsoString invoice.issuedAt
            ]
        , row [ Background.color (rgb 0.9 0.9 0.9) ]
            [ el [ Font.heavy ] <| text "Balance Due"
            , text <| String.fromFloat <| Invoice.total invoice
            ]
        ]


viewInvoiceAmounts invoice =
    let
        line label amount =
            row [ width fill ] [ text label, text <| String.fromFloat amount ]
    in
    column [ alignRight, width (px 200) ]
        [ line "Subtotal" (Invoice.subTotal invoice)
        , line "Total" (Invoice.total invoice)
        , line "Balance Due" (Invoice.total invoice)
        ]


viewSupplier supplier =
    column [ spacing 5 ]
        [ text supplier.name
        , text supplier.email
        , text supplier.phone
        , column [] <| List.map text <| String.split "\n" supplier.address
        , text <| "VAT Number: " ++ supplier.regNum
        ]


viewCustomer customer =
    column [ spacing 5 ]
        [ text customer.name
        , text customer.email
        , text customer.phone
        , column [] <| List.map text <| String.split "\n" customer.address
        , text <| "VAT Number: " ++ customer.taxNum
        ]


viewTerms : String -> Element msg
viewTerms terms =
    column []
        (terms
            |> String.split "\n"
            |> List.map text
        )



-- HTTP


decoder : Decoder Invoice
decoder =
    JD.map2 Tuple.pair
        (JD.field "Count" JD.int)
        (JD.field "Items" JD.value)
        |> JD.andThen
            (\( count, items ) ->
                items
                    |> JD.decodeValue (JD.index 0 Invoice.decoder)
                    |> Result.map
                        (\invoice ->
                            (List.range 1 (count - 1)
                                |> List.map
                                    (\i ->
                                        JD.decodeValue (JD.index i Item.decoder) items
                                    )
                            )
                                |> combine
                                |> Result.map
                                    (\invoiceItems ->
                                        JD.succeed { invoice | items = invoiceItems }
                                    )
                                |> Result.withDefault (JD.fail "Invalid invoice item")
                        )
                    |> Result.withDefault (JD.fail "Invalid invoice")
            )


fetchInvoices : Ulid -> Task Http.Error Invoice
fetchInvoices invoiceId =
    let
        pk =
            "INVOICE#" ++ Ulid.toString invoiceId
    in
    { operation = Api.Query
    , indexName = "GSI1"
    , keyConditionExpression = "GSI1PK = :pk"
    , expressionAttributeValues =
        Encode.object
            [ ( ":pk"
              , Encode.object
                    [ ( "S", Encode.string pk ) ]
              )
            ]
    , decoder = decoder
    }
        |> Api.request
