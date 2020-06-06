module Api exposing (Operation(..), buildBody, request, send)

import AWS.Config
import AWS.Credentials
import AWS.Http
import AWS.Service
import Constants
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task exposing (Task)


type Operation
    = Query
    | PutItem
    | Scan


send : AWS.Http.Request a -> Task Http.Error a
send req =
    AWS.Http.send service credentials req


request :
    { operation : Operation
    , indexName : String
    , keyConditionExpression : String
    , expressionAttributeValues : Encode.Value
    , decoder : Decode.Decoder a
    }
    -> AWS.Http.Request a
request opts =
    let
        path =
            ""
    in
    AWS.Http.request
        (operationToString opts.operation)
        AWS.Http.POST
        path
        (buildBody opts)
        (AWS.Http.jsonBodyDecoder opts.decoder)



-- Helpers


buildBody :
    { r
        | indexName : String
        , keyConditionExpression : String
        , expressionAttributeValues : Encode.Value
    }
    -> AWS.Http.Body
buildBody { indexName, keyConditionExpression, expressionAttributeValues } =
    Encode.object
        [ ( "TableName", Encode.string Constants.tableName )
        , ( "IndexName", Encode.string indexName )
        , ( "KeyConditionExpression", Encode.string keyConditionExpression )
        , ( "ExpressionAttributeValues", expressionAttributeValues )
        ]
        |> AWS.Http.jsonBody


service : AWS.Service.Service
service =
    let
        endpointPrefix =
            "DynamoDB"

        apiVersion =
            "20120810"

        targetPrefix =
            endpointPrefix ++ "_" ++ apiVersion
    in
    AWS.Config.defineRegional
        (String.toLower endpointPrefix)
        apiVersion
        AWS.Config.JSON
        AWS.Config.SignV4
        Constants.awsRegion
        |> AWS.Config.withTargetPrefix targetPrefix
        |> AWS.Service.service


credentials : AWS.Credentials.Credentials
credentials =
    AWS.Credentials.fromAccessKeys
        Constants.accessKeyId
        Constants.secretAccessKey


operationToString : Operation -> String
operationToString operation =
    case operation of
        Query ->
            "Query"

        Scan ->
            "Scan"

        PutItem ->
            "PutItem"
