module Route exposing (Route(..), fromUrl, toString)

import Ulid exposing (Ulid)
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)


type Route
    = Invoice Ulid
    | Client Ulid


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Invoice (s "invoice" </> ulidParser)
        , Parser.map Client (s "client" </> ulidParser)
        ]


ulidParser : Parser (Ulid -> a) a
ulidParser =
    Parser.custom "ULID" Ulid.fromString


toString : Route -> String
toString route =
    case route of
        Invoice invoiceId ->
            absolute [ "invoice", Ulid.toString invoiceId ] []

        Client clientId ->
            absolute [ "client", Ulid.toString clientId ] []


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url
