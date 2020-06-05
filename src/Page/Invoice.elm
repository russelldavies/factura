module Page.Invoice exposing (Model, Msg, init, update, view)

import Element exposing (Element)
import Invoice exposing (Invoice)
import Page
import Ulid exposing (Ulid)



-- MODEL --


type alias Model =
    Maybe Invoice


init : Ulid -> ( Model, Cmd Msg )
init invoiceId =
    ( Nothing, Cmd.none )



-- UPDATE --


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- VIEW --


view : Model -> Page.Document Msg
view model =
    { title = "Invoice"
    , content = Element.text "invoice"
    }
