module Page.Invoice exposing (Model, Msg, init, update, view)

import Api
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Http
import Invoice exposing (Invoice)
import Invoice.Customer as Customer exposing (Customer)
import Invoice.LineItem as LineItem exposing (LineItem)
import Invoice.Supplier as Supplier exposing (Supplier)
import Iso8601
import Json.Decode as JD exposing (Decoder)
import Json.Encode as Encode
import Money exposing (Currency)
import Page
import RemoteData exposing (RemoteData(..), WebData)
import Result.Extra exposing (combine)
import Route
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
    = InvoiceResponse (WebData Invoice)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InvoiceResponse response ->
            ( response, Cmd.none )



-- VIEW --


view : Model -> Page.Document Msg
view model =
    { title =
        case model of
            Success invoice ->
                "Invoice " ++ Invoice.formatNumber invoice

            _ ->
                "Invoice"
    , content =
        case model of
            NotAsked ->
                text "Initialising..."

            Loading ->
                none

            Failure err ->
                text "Something failed! We've been notified and will be right on it."

            Success invoice ->
                column [ width fill ]
                    [ viewInvoice invoice
                    , link []
                        { url = Route.toString (Route.Client invoice.clientId)
                        , label = el [ Font.underline ] <| text "View all invoices"
                        }
                    ]
    }


viewInvoice : Invoice -> Element msg
viewInvoice invoice =
    column [ width fill, padding 10 ]
        [ row [ Font.size 24, Font.heavy, spacing 5 ]
            [ text "Invoice:"
            , text << Invoice.formatNumber <| invoice
            ]
        , column
            [ Border.solid
            , Border.width 1
            , padding 10
            , spacing 20
            , width fill
            ]
            [ viewSupplier invoice.supplier
            , row [ width fill ]
                [ viewCustomer invoice.customer
                , el [ alignTop, alignRight ] <| viewInvoiceDetails invoice
                ]
            , viewItemDetails invoice.currency invoice.lineItems
            , viewInvoiceAmounts invoice
            , row [ width fill ]
                [ viewTerms invoice.terms
                , viewNotes invoice.notes
                ]
            ]
        ]


viewItemDetails : Currency -> List LineItem -> Element msg
viewItemDetails currency items =
    let
        header attr =
            el [ Background.color (rgb 0.9 0.9 0.9), Font.heavy ] << el [ attr ] << text

        quantityText lineItem =
            String.fromFloat lineItem.quantity
                ++ " "
                ++ lineItem.rate.unit

        cell s =
            el [] (el [ alignRight ] <| text s)
    in
    table
        [ spacingXY 0 10
        , paddingEach { top = 0, bottom = 15, left = 0, right = 0 }
        , Border.width 1
        , Border.color (rgba 0 0 0 0.1)
        ]
        { data = items
        , columns =
            [ { header = header alignLeft "Description"
              , width = fillPortion 6
              , view = .description >> text >> List.singleton >> paragraph []
              }
            , { header = header alignRight ("Rate (" ++ currency.symbol ++ ")")
              , width = fill
              , view = .rate >> .cost >> format usLocale >> cell
              }
            , { header = header alignRight "Quantity"
              , width = fill
              , view = quantityText >> cell
              }
            , { header = header alignRight ("Line Total (" ++ currency.symbol ++ ")")
              , width = fill
              , view = LineItem.total >> format usLocale >> cell
              }
            ]
        }


viewInvoiceDetails invoice =
    let
        line heading e =
            row [ width fill, spacing 80 ] [ text heading, el [ alignRight ] e ]
    in
    column []
        [ line "Invoice #" (text <| Invoice.formatNumber invoice)
        , line "Issued On" (text <| formatDate invoice.issuedOn)
        , line "Paid On"
            (case invoice.paidOn of
                Just date ->
                    text <| formatDate date

                Nothing ->
                    el [ Font.color (rgb 1 0 0) ] <| text "Unpaid"
            )
        ]


viewInvoiceAmounts invoice =
    let
        line label amount =
            row [ width fill, spacing 80 ]
                [ el [ Font.heavy ] <| text label
                , el [ Font.heavy, alignRight ] <| text <| format usLocale amount
                ]

        taxLine label amount =
            row [ width fill, spacing 80 ]
                [ el [] <| text label
                , el [ alignRight ] <| text <| format usLocale amount
                ]

        balanceDue =
            if invoice.paidOn == Nothing then
                Invoice.total invoice

            else
                0
    in
    column [ alignRight ]
        [ line "Subtotal" (Invoice.subTotal invoice)
        , column [ width fill ] <|
            List.map
                (\( taxName, amount ) -> taxLine taxName amount)
                (Invoice.taxes invoice)
        , line "Total" (Invoice.total invoice)
        , row
            [ width fill
            , spacing 80
            , Background.color (rgb 0.9 0.9 0.9)
            ]
            [ el [ Font.heavy ] <| text ("Balance Due (" ++ invoice.currency.code ++ ")")
            , el [ alignRight ] <| text <| (invoice.currency.symbol ++ format usLocale balanceDue)
            ]
        ]


viewSupplier : Supplier -> Element msg
viewSupplier supplier =
    column []
        [ Maybe.map text supplier.company |> Maybe.withDefault none
        , Maybe.map text supplier.name |> Maybe.withDefault none
        , viewAddress supplier.address
        , row [ Font.heavy, spacing 5 ]
            [ text supplier.taxNumber.name
            , text supplier.taxNumber.number
            ]
        ]


viewCustomer : Customer -> Element msg
viewCustomer customer =
    column []
        [ Maybe.map text customer.company |> Maybe.withDefault none
        , Maybe.map text customer.name |> Maybe.withDefault none
        , text customer.email
        , Maybe.map text customer.phone |> Maybe.withDefault none
        , viewAddress customer.address
        ]


viewAddress : String -> Element msg
viewAddress address =
    column [] <| List.map text <| String.split "\n" address


viewTerms : String -> Element msg
viewTerms terms =
    (el [ Font.heavy ] (text "Terms") :: (terms |> String.split "\n" |> List.map text))
        |> column [ alignTop ]


viewNotes : String -> Element msg
viewNotes notes =
    if String.isEmpty notes then
        none

    else
        (el [ Font.heavy ] (text "Notes") :: (notes |> String.split "\n" |> List.map text))
            |> column [ alignTop, alignRight ]


formatDate =
    Iso8601.fromTime >> String.left 10



-- HTTP


decoder : Decoder Invoice
decoder =
    JD.map2 Tuple.pair
        (JD.field "Count" JD.int)
        (JD.field "Items" JD.value)
        |> JD.andThen
            (\( count, items ) ->
                case JD.decodeValue (JD.index 0 Invoice.decoder) items of
                    Ok invoice ->
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
                            |> Result.withDefault (JD.fail "LINE ITEM")

                    Err err ->
                        JD.fail ("Invoice: " ++ JD.errorToString err)
            )


fetchInvoices : Ulid -> Task Http.Error Invoice
fetchInvoices invoiceId =
    let
        pk =
            "INVOICE#" ++ Ulid.toString invoiceId
    in
    { operation = Api.Query
    , indexName = Just "GSI1"
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
