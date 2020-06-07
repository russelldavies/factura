module Page.Invoice exposing (Model, Msg, init, update, view)

import Api
import Element exposing (Element, column, text)
import Element.Border as Border
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
    text "invoice"



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
