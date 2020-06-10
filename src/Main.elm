module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import Page
import Page.Client as Client
import Page.Invoice as Invoice
import Page.NotFound as NotFound
import Route exposing (Route)
import Ulid exposing (Ulid)
import Url exposing (Url)



-- MODEL


type alias Model =
    { key : Nav.Key
    , page : Page
    }


type Page
    = NotFound
    | Invoice Invoice.Model
    | Client Client.Model


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( page, pageCmd ) =
            initPage (Route.fromUrl url)
    in
    ( { key = key, page = page }
    , Cmd.map GotPageMsg pageCmd
    )



-- UPDATE


type Msg
    = ClickedLink Browser.UrlRequest
    | ChangedUrl Url
    | GotPageMsg PageMsg


type PageMsg
    = InvoiceMsg Invoice.Msg
    | ClientMsg Client.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        mapPageUpdate ( page, pageCmd ) =
            ( { model | page = page }
            , Cmd.map GotPageMsg pageCmd
            )
    in
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                Browser.External href ->
                    ( model, Nav.load href )

        ChangedUrl url ->
            initPage (Route.fromUrl url)
                |> mapPageUpdate

        GotPageMsg pageMsg ->
            updatePage pageMsg model.page
                |> mapPageUpdate


updatePage : PageMsg -> Page -> ( Page, Cmd PageMsg )
updatePage pageMsg page =
    case ( pageMsg, page ) of
        ( InvoiceMsg subMsg, Invoice pageModel ) ->
            Invoice.update subMsg pageModel
                |> mapPage Invoice InvoiceMsg

        ( ClientMsg subMsg, Client pageModel ) ->
            Client.update subMsg pageModel
                |> mapPage Client ClientMsg

        _ ->
            ( NotFound, Cmd.none )


initPage : Maybe Route -> ( Page, Cmd PageMsg )
initPage maybeRoute =
    case maybeRoute of
        Nothing ->
            ( NotFound, Cmd.none )

        Just (Route.Invoice invoiceId) ->
            Invoice.init invoiceId
                |> mapPage Invoice InvoiceMsg

        Just (Route.Client customerId) ->
            Client.init customerId
                |> mapPage Client ClientMsg


mapPage :
    (subModel -> Page)
    -> (subMsg -> PageMsg)
    -> ( subModel, Cmd subMsg )
    -> ( Page, Cmd PageMsg )
mapPage toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        frame toMsg config =
            let
                { title, body } =
                    Page.view config
            in
            { title = title
            , body = List.map (Html.map (toMsg >> GotPageMsg)) body
            }
    in
    case model.page of
        NotFound ->
            frame never NotFound.view

        Invoice invoice ->
            frame InvoiceMsg (Invoice.view invoice)

        Client customer ->
            frame ClientMsg (Client.view customer)



-- PROGRAM


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }
