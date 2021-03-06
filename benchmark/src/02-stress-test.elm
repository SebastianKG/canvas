module Main exposing (..)

import Html exposing (Html, div, button, text, table, thead, tr, th, tbody, td)
import Html.Attributes exposing (disabled, style)
import Html.Events exposing (onClick)
import Color exposing (Color)
import Random
import Task
import Date exposing (Date)
import Time exposing (Time)
import Canvas exposing (Canvas, Position, Size)


-- Constants


numberOfRects : Int
numberOfRects =
    500


resolution : Size
resolution =
    Size 800 600


rectSize : Size
rectSize =
    Size 100 100



-- Main


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- Types


type alias Model =
    { canvas : Canvas
    , testStartedAt : Float
    , rectangles : List Rectangle
    , results : List TestResult
    , positionGenerator : Random.Generator Position
    , colorGenerator : Random.Generator Color
    }


type alias Rectangle =
    { position : Position
    , size : Size
    , color : Color
    }


type alias TestResult =
    { index : String
    , average : Float
    , totalTime : Float
    }


init : ( Model, Cmd Msg )
init =
    let
        canvas : Canvas
        canvas =
            Size resolution.width resolution.height
                |> Canvas.initialize

        model : Model
        model =
            { canvas = canvas
            , testStartedAt = 0
            , rectangles = []
            , results = []
            , positionGenerator = Random.map2 Position (Random.int 0 (resolution.width - rectSize.width)) (Random.int 0 (resolution.height - rectSize.height))
            , colorGenerator = Random.map3 Color.rgb (Random.int 0 255) (Random.int 0 255) (Random.int 0 255)
            }
    in
        ( model
        , Random.generate RandomPosition model.positionGenerator
        )


defaultRect : Rectangle
defaultRect =
    Rectangle
        (Position 0 0)
        rectSize
        (Color.rgb 0 0 0)



-- Update


type Msg
    = Benchmark
    | TestBegin Float
    | TestEnd Float
    | RandomPosition Position
    | RandomColor Position Color


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Benchmark ->
            ( model
            , Task.perform TestBegin Time.now
            )

        TestBegin timestamp ->
            let
                canvas : Canvas
                canvas =
                    Size resolution.width resolution.height
                        |> Canvas.initialize

                canvasWithRects : Canvas
                canvasWithRects =
                    model.rectangles
                        |> List.foldl render canvas

                render : Rectangle -> Canvas -> Canvas
                render rectangle previousCanvas =
                    let
                        rectCanvas : Canvas
                        rectCanvas =
                            rectangle.size
                                |> Canvas.initialize
                                |> Canvas.fill rectangle.color
                    in
                        Canvas.drawCanvas rectCanvas rectangle.position previousCanvas
            in
                ( { model
                    | canvas = canvasWithRects
                    , testStartedAt = timestamp
                  }
                , Task.perform TestEnd Time.now
                )

        TestEnd timestamp ->
            let
                result : TestResult
                result =
                    let
                        delta : Float
                        delta =
                            timestamp - model.testStartedAt

                        average : Float
                        average =
                            delta / (toFloat (List.length model.rectangles))
                    in
                        { index = toString ((List.length model.results) + 1)
                        , average = average
                        , totalTime = delta
                        }

                results : List TestResult
                results =
                    List.append model.results [ result ]
            in
                ( { model | results = results }
                , Cmd.none
                )

        RandomPosition position ->
            if (List.length model.rectangles) < numberOfRects then
                ( model
                , Random.generate (RandomColor position) model.colorGenerator
                )
            else
                ( model
                , Cmd.none
                )

        RandomColor position color ->
            let
                rectangle : Rectangle
                rectangle =
                    Rectangle
                        position
                        rectSize
                        color

                rectangles : List Rectangle
                rectangles =
                    List.append model.rectangles [ rectangle ]
            in
                ( { model | rectangles = rectangles }
                , Random.generate RandomPosition model.positionGenerator
                )



-- View


view : Model -> Html Msg
view model =
    let
        resultsHtml : List TestResult -> Html Msg
        resultsHtml results =
            let
                msToString : Float -> String
                msToString milliseconds =
                    (toString milliseconds) ++ "ms"

                tdStyles : List ( String, String )
                tdStyles =
                    [ ( "border-top", "1px black solid" )
                    , ( "text-align", "center" )
                    ]

                tdAttributes : List (Html.Attribute Msg)
                tdAttributes =
                    [ style tdStyles
                    ]

                renderRow : TestResult -> Html Msg
                renderRow result =
                    tr
                        []
                        [ td
                            [ style [ ( "border-top", "1px black solid" ) ] ]
                            [ text (result.index ++ ".") ]
                        , td tdAttributes [ text (msToString result.average) ]
                        , td tdAttributes [ text (msToString result.totalTime) ]
                        ]

                thStyle : List ( String, String )
                thStyle =
                    [ ( "width", "100px" )
                    ]
            in
                if (List.length results) > 0 then
                    table
                        [ style
                            [ ( "border-collapse", "collapse" )
                            ]
                        ]
                        [ thead
                            []
                            [ tr
                                []
                                [ th [ style thStyle ] [ text "" ]
                                , th [ style thStyle ] [ text "Average" ]
                                , th [ style thStyle ] [ text "Total time" ]
                                ]
                            ]
                        , tbody
                            []
                            (List.map renderRow results)
                        ]
                else
                    text ""

        averageResult : TestResult
        averageResult =
            { index = "Average"
            , average = (\sum -> sum / (toFloat <| List.length model.results)) <| List.sum <| List.map .average model.results
            , totalTime = (\sum -> sum / (toFloat <| List.length model.results)) <| List.sum <| List.map .totalTime model.results
            }

        allResults : List TestResult
        allResults =
            if (List.length model.results) > 1 then
                List.append model.results [ averageResult ]
            else
                model.results

        buttonDisabled : Bool
        buttonDisabled =
            (List.length model.rectangles) < numberOfRects

        buttonText : String
        buttonText =
            if buttonDisabled then
                "Preloading rectangle data..."
            else
                "Begin benchmark"
    in
        div
            []
            [ div
                []
                [ text
                    ("Average time to render "
                        ++ (toString numberOfRects)
                        ++ " opaque rectangles on a "
                        ++ (toString resolution.width)
                        ++ "x"
                        ++ (toString resolution.height)
                        ++ " canvas"
                    )
                ]
            , div
                []
                [ button
                    [ onClick Benchmark
                    , disabled buttonDisabled
                    ]
                    [ text buttonText ]
                ]
            , Canvas.toHtml [] model.canvas
            , resultsHtml allResults
            ]
