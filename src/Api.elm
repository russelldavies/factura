module Api exposing (Operation(..), buildBody, request)

import AWS.Config
import AWS.Credentials
import AWS.Http
import AWS.Service
import Constants
import DynamoDb
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task exposing (Task)


type Operation
    = Query
    | PutItem
    | Scan


request :
    { operation : Operation
    , indexName : Maybe String
    , keyConditionExpression : String
    , expressionAttributeValues : Encode.Value
    , decoder : Decode.Decoder a
    }
    -> Task Http.Error a
request opts =
    let
        path =
            ""

        credentials =
            AWS.Credentials.fromAccessKeys
                authConfig.accessKeyId
                authConfig.secretAccessKey
    in
    AWS.Http.request
        (operationToString opts.operation)
        AWS.Http.POST
        path
        (AWS.Http.jsonBody <| buildBody opts)
        (AWS.Http.jsonBodyDecoder opts.decoder)
        |> AWS.Http.send service credentials



-- Helpers


buildBody :
    { r
        | indexName : Maybe String
        , keyConditionExpression : String
        , expressionAttributeValues : Encode.Value
    }
    -> Encode.Value
buildBody { indexName, keyConditionExpression, expressionAttributeValues } =
    case indexName of
        Just indexName_ ->
            Encode.object
                [ ( "TableName", Encode.string Constants.tableName )
                , ( "IndexName", Encode.string indexName_ )
                , ( "KeyConditionExpression", Encode.string keyConditionExpression )
                , ( "ExpressionAttributeValues", expressionAttributeValues )
                ]

        Nothing ->
            Encode.object
                [ ( "TableName", Encode.string Constants.tableName )
                , ( "KeyConditionExpression", Encode.string keyConditionExpression )
                , ( "ExpressionAttributeValues", expressionAttributeValues )
                ]


service : AWS.Service.Service
service =
    AWS.Config.defineRegional
        authConfig.serviceName
        "NOT USED"
        AWS.Config.JSON
        AWS.Config.SignV4
        Constants.awsRegion
        |> AWS.Config.withTargetPrefix (apiConfig.name ++ "_" ++ apiConfig.version)
        |> AWS.Service.service


authConfig =
    { awsRegion = Constants.awsRegion
    , serviceName = "dynamodb"
    , accessKeyId = Constants.accessKeyId
    , secretAccessKey = Constants.secretAccessKey
    , sessionToken = Nothing
    }


apiConfig =
    { name = "DynamoDB"
    , version = "20120810"
    }


operationToString : Operation -> String
operationToString operation =
    case operation of
        Query ->
            "Query"

        Scan ->
            "Scan"

        PutItem ->
            "PutItem"
