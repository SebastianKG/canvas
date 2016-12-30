import Html exposing (p, text, div, canvas, Html)
import Html.Attributes exposing (id, style)
import Html.Events exposing (..)
import Canvas exposing (Canvas, Pixel)
import List exposing (repeat, concat)
import Mouse exposing (Position)
import Array exposing (fromList)
import Color exposing (rgb, Color)
import Debug exposing (log)


main = 
  Html.program
  { init  = (model, Cmd.none) 
  , view   = view 
  , update = update
  , subscriptions = always Sub.none
  }


-- MODEL


type alias Model = Canvas


type Msg
  = Draw Position


model : Canvas
model =
  let
    width  = 500
    height = 400
  in
  { id = "the-canvas"
  , imageData =
    { width  = width
    , height = height
    , data   = 
        black
        |>repeat (width * height)
        |>concat
        |>fromList
    }
  }


black : List Int
black =
  [ 0, 0, 0, 255 ]


prettyBlue : Color
prettyBlue =
  rgb 23 92 254



-- UPDATE


update :  Msg -> Model -> (Model, Cmd Msg)
update message canvas =
  case message of 

    Draw position ->
      let 
        updatedCanvas =
          Canvas.putPixels
            canvas
            [ Pixel prettyBlue position ]
      in
      (updatedCanvas, Cmd.none)



-- VIEW



view : Model -> Html Msg
view canvas =
  div 
  [] 
  [ p [] [ text "Elm-Canvas" ]
  , Canvas.toHtml 
      canvas 
      [ Canvas.onMouseDown Draw ]
  ]