module Page.NotFound exposing (view)

import Element exposing (Element)
import Page


view : Page.Document msg
view =
    { title = "Not Found"
    , content = Element.text "Not Found"
    }
