module Page.Customer exposing (Model, Msg, init, update, view)

import Customer exposing (Customer)
import Element exposing (Element)
import Page
import Ulid exposing (Ulid)



-- MODEL --


type alias Model =
    Maybe Customer


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
    { title = "Customer"
    , content = Element.text "customer page"
    }
