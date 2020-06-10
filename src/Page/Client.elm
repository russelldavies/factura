module Page.Client exposing (Model, Msg, init, update, view)

import Client exposing (Client)
import Element exposing (Element)
import Page
import Ulid exposing (Ulid)



-- MODEL --


type alias Model =
    Maybe Client


init : Ulid -> ( Model, Cmd Msg )
init customerId =
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


view : Model -> Page.Document msg
view model =
    { title = "Client"
    , content = Element.text "client page"
    }
