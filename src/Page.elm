module Page exposing (Document, view)

import Browser
import Element exposing (Element, padding, spacing)
import Element.Font as Font
import Html
import Ulid exposing (Ulid)


type alias Document msg =
    { title : String
    , content : Element msg
    }


view : Document msg -> Browser.Document msg
view { title, content } =
    { title = title ++ " - Factura"
    , body =
        [ Element.layout
            [ Font.size 14
            , Font.family
                [ Font.external
                    { name = "Source Sans Pro"
                    , url = "https://fonts.googleapis.com/css2?family=Source+Sans+Pro&display=swap"
                    }
                , Font.typeface "Source Sans Pro"
                , Font.sansSerif
                ]
            ]
            content
        ]
    }
