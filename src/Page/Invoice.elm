module Page.Invoice exposing (Model, Msg, init, update, view)

import Api
import Date
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Http
import Invoice exposing (Invoice)
import Invoice.Customer as Customer exposing (Customer)
import Invoice.LineItem as LineItem exposing (LineItem)
import Invoice.Supplier as Supplier exposing (Supplier)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as Encode
import Money exposing (Currency)
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


invoiceNum invoice =
    String.padLeft 7 '0' invoice.number



-- VIEW --


view : Model -> Page.Document Msg
view model =
    { title =
        case model of
            Success invoice ->
                "Invoice " ++ invoiceNum invoice

            _ ->
                "Invoice"
    , content =
        case model of
            NotAsked ->
                text "Initialising..."

            Loading ->
                text "Loading..."

            Failure err ->
                text "Something failed! We've been notified and will be right on it."

            Success invoice ->
                viewInvoice invoice
    }


viewInvoice : Invoice -> Element msg
viewInvoice invoice =
    column [ width fill ]
        [ row [ Font.size 24, Font.heavy, spacing 5 ]
            [ text "Invoice:"
            , text << invoiceNum <| invoice
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
            , viewItemDetails invoice.currency invoice.lineItems
            , viewInvoiceAmounts invoice
            , viewTerms invoice.terms
            ]
        ]


viewItemDetails : Currency -> List LineItem -> Element msg
viewItemDetails currency items =
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
            [ { header = header "Description"
              , width = fillPortion 6
              , view = .description >> text >> List.singleton >> paragraph []
              }
            , { header = header ("Rate (" ++ currency.symbol ++ ")")
              , width = fill
              , view = .rate >> .cost >> String.fromFloat >> text
              }
            , { header = header "Quantity"
              , width = fill
              , view =
                    \lineItem ->
                        text
                            (String.fromFloat lineItem.quantity
                                ++ " "
                                ++ lineItem.rate.unit
                            )
              }
            , { header = header ("Line Total (" ++ currency.symbol ++ ")")
              , width = fill
              , view = LineItem.subTotal >> String.fromFloat >> text
              }
            ]
        }


viewInvoiceDetails invoice =
    column []
        [ row []
            [ text "Invoice #"
            , text << invoiceNum <| invoice
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


viewSupplier : Supplier -> Element msg
viewSupplier supplier =
    column [ spacing 5 ]
        [ Maybe.map text supplier.company |> Maybe.withDefault none
        , Maybe.map text supplier.name |> Maybe.withDefault none
        , text supplier.email
        , Maybe.map text supplier.phone |> Maybe.withDefault none
        , column [] <| List.map text <| String.split "\n" supplier.address
        , row [] [ text supplier.taxNumber.name, text supplier.taxNumber.number ]
        ]


viewCustomer : Customer -> Element msg
viewCustomer customer =
    column [ spacing 5 ]
        [ Maybe.map text customer.company |> Maybe.withDefault none
        , Maybe.map text customer.name |> Maybe.withDefault none
        , text customer.email
        , Maybe.map text customer.phone |> Maybe.withDefault none
        , column [] <| List.map text <| String.split "\n" customer.address
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
                                        JD.decodeValue (JD.index i LineItem.decoder) items
                                    )
                            )
                                |> combine
                                |> Result.map
                                    (\invoiceItems ->
                                        JD.succeed { invoice | lineItems = invoiceItems }
                                    )
                                |> Result.withDefault (JD.fail "Invalid line item")
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
