module Page.Client exposing (Model, Msg, init, update, view)

import Api
import Client exposing (Client)
import Element exposing (..)
import Element.Font as Font
import Http
import Invoice exposing (Invoice)
import Iso8601
import Json.Decode as JD exposing (Decoder)
import Json.Encode as Encode
import Page
import RemoteData exposing (RemoteData(..), WebData)
import Result.Extra exposing (combine)
import Route
import Task exposing (Task)
import Ulid exposing (Ulid)



-- MODEL --


type alias Model =
    WebData Client


init : Ulid -> ( Model, Cmd Msg )
init clientId =
    ( RemoteData.Loading
    , Task.attempt (RemoteData.fromResult >> ClientResponse) (fetchClient clientId)
    )



-- UPDATE --


type Msg
    = ClientResponse (WebData Client)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClientResponse response ->
            ( response, Cmd.none )



-- VIEW --


view : Model -> Page.Document Msg
view model =
    { title = "Client Invoices"
    , content =
        case model of
            NotAsked ->
                text "Initialising..."

            Loading ->
                none

            Failure err ->
                text "Something failed! We've been notified and will be right on it."

            Success client ->
                column
                    [ padding 10
                    , width fill
                    , spacing 20
                    ]
                    [ viewClient client
                    , viewInvoices client.invoices
                    ]
    }


viewClient : Client -> Element msg
viewClient client =
    column []
        [ el [ Font.size 24 ] <| text "Client Details"
        , Maybe.map text client.company |> Maybe.withDefault none
        , Maybe.map text client.name |> Maybe.withDefault none
        , text client.email
        , Maybe.map text client.phone |> Maybe.withDefault none
        , viewAddress client.address
        ]


viewInvoices : List Invoice -> Element msg
viewInvoices invoices =
    column [ width fill ]
        [ el [ Font.size 24 ] <| text "Invoices"
        , table []
            { data = invoices
            , columns =
                [ { header = text "Number"
                  , width = fill
                  , view =
                        \invoice ->
                            link []
                                { url = Route.toString (Route.Invoice invoice.invoiceId)
                                , label = el [ Font.underline ] <| text <| Invoice.formatNumber invoice
                                }
                  }
                , { header = text "Issued On"
                  , width = fill
                  , view = .issuedOn >> formatDate >> text
                  }
                , { header = text "Paid On"
                  , width = fill
                  , view =
                        \invoice ->
                            case invoice.paidOn of
                                Just paidOn ->
                                    text <| formatDate paidOn

                                Nothing ->
                                    el [ Font.color (rgb 1 0 0) ] <| text "Unpaid"
                  }
                ]
            }
        ]


viewAddress : String -> Element msg
viewAddress address =
    column [] <| List.map text <| String.split "\n" address


formatDate =
    Iso8601.fromTime >> String.left 10



-- HTTP


decoder : Decoder Client
decoder =
    JD.map2 Tuple.pair
        (JD.field "Count" JD.int)
        (JD.field "Items" JD.value)
        |> JD.andThen
            (\( count, items ) ->
                case JD.decodeValue (JD.index 0 Client.decoder) items of
                    Ok client ->
                        (List.range 1 (count - 1)
                            |> List.map
                                (\i ->
                                    JD.decodeValue (JD.index i Invoice.decoder) items
                                )
                        )
                            |> combine
                            |> Result.map
                                (\invoices ->
                                    JD.succeed { client | invoices = invoices }
                                )
                            |> Result.withDefault (JD.fail "Invoice")

                    Err err ->
                        JD.fail ("Client: " ++ JD.errorToString err)
            )


fetchClient : Ulid -> Task Http.Error Client
fetchClient clientId =
    let
        pk =
            "CLIENT#" ++ Ulid.toString clientId
    in
    { operation = Api.Query
    , indexName = Nothing
    , keyConditionExpression = "PK = :pk"
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
