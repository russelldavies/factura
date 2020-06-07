module DynamoDb exposing (..)

import Bytes exposing (Bytes)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra exposing (parseFloat)
import Set exposing (Set)



-- TYPES


type alias Item =
    List Attribute


type alias Attribute =
    ( String, Value )


type Value
    = DynamoNum Float -- TODO: replace with DynamoNum
    | DynamoStr String
    | DynamoBin String -- TODO: replace with Bytes
    | DynamoBool Bool
    | DynamoNull
    | DynamoList (List Value)
    | DynamoMap (List ( String, Value ))
    | DynamoStrSet (Set String)
    | DynamoNumSet (Set Float)
    | DynamoBinSet (Set String)


type alias DynamoNum_ =
    { int : Int
    , frac : List Int
    , exponent : Int
    }


type alias Response =
    { count : Int
    , scannedCount : Int
    , items : List Item
    }



-- DECODERS


responseDecoder : Decoder Response
responseDecoder =
    Decode.map3 Response
        (Decode.field "Count" Decode.int)
        (Decode.field "ScannedCount" Decode.int)
        (Decode.field "Items" (Decode.list itemDecoder))


itemDecoder : Decoder Item
itemDecoder =
    Decode.keyValuePairs valueDecoder


valueDecoder : Decoder Value
valueDecoder =
    Decode.oneOf
        [ Decode.field "B" (Decode.string |> Decode.map DynamoBin)
        , Decode.field "BOOL" (Decode.bool |> Decode.map DynamoBool)
        , Decode.field "BS" (Decode.list Decode.string |> Decode.map (Set.fromList >> DynamoBinSet))
        , Decode.field "L" (Decode.list (Decode.lazy (\_ -> valueDecoder))) |> Decode.map DynamoList
        , Decode.field "M" (Decode.keyValuePairs (Decode.lazy (\_ -> valueDecoder))) |> Decode.map DynamoMap
        , Decode.field "N" (parseFloat |> Decode.map DynamoNum)
        , Decode.field "NS" (Decode.list parseFloat) |> Decode.map (Set.fromList >> DynamoNumSet)
        , Decode.field "NULL" (Decode.null DynamoNull)
        , Decode.field "S" (Decode.string |> Decode.map DynamoStr)
        , Decode.field "SS" (Decode.list Decode.string) |> Decode.map (Set.fromList >> DynamoStrSet)
        ]
