module Page.Invoice exposing (Model, Msg, init, update, view)

import Api
import Element exposing (Element)
import Http
import Invoice exposing (Invoice)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Page
import Task exposing (Task)
import Ulid exposing (Ulid)



-- MODEL --


type alias Model =
    Maybe Invoice


init : Ulid -> ( Model, Cmd Msg )
init invoiceId =
    ( Nothing, Task.attempt LoadedInvoices fetchInvoices )



-- UPDATE --


type Msg
    = NoOp
    | LoadedInvoices (Result Http.Error (List Invoice))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "" msg of
        NoOp ->
            ( model, Cmd.none )

        LoadedInvoices (Ok invoices) ->
            ( List.head invoices, Cmd.none )

        LoadedInvoices (Err err) ->
            ( model, Cmd.none )



-- VIEW --


view : Model -> Page.Document Msg
view model =
    { title = "Invoice"
    , content = Element.text <| Debug.toString model
    }



-- HTTP


reqOpts =
    { operation = Api.Query
    , indexName = "GSI1"
    , keyConditionExpression = "GSI1PK = :pk and GSI1SK = :pk"
    , expressionAttributeValues =
        Encode.object
            [ ( ":pk"
              , Encode.object
                    [ ( "S", Encode.string "INVOICE#01EA0E73EM8V4ZTB5VT48HQCH9" ) ]
              )
            ]
    , decoder = decoder
    }


decoder : Decoder (List Invoice)
decoder =
    Decode.field "Items" (Decode.list Invoice.decoder)


fetchInvoices : Task Http.Error (List Invoice)
fetchInvoices =
    Api.send <| Api.request reqOpts
