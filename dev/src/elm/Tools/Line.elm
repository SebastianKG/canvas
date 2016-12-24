module Line exposing (..)

import Mouse exposing (Position)


line : Position -> Position -> List Position
line =
  bresenhamLine


type alias BresenhamStatics = 
  { finish : Position, sx : Int, sy : Int, dx : Float, dy : Float }


bresenhamLine : Position -> Position -> List Position
bresenhamLine p q  =
  let
    dx = (toFloat << abs) (q.x - p.x)
    sx = if p.x < q.x then 1 else -1
    dy = (toFloat << abs) (q.y - p.y)
    sy = if p.y < q.y then 1 else -1

    error =
      (if dx > dy then dx else -dy) / 2

    statics = 
      BresenhamStatics q sx sy dx dy 
  in
  bresenhamLineLoop statics error p []


bresenhamLineLoop : BresenhamStatics -> Float -> Position -> List Position -> List Position
bresenhamLineLoop statics error p positions =
  let 
    positions_ = p :: positions 
    {sx, sy, dx, dy, finish} = statics
  in
  if (p.x == finish.x) && (p.y == finish.y) then positions_
  else
    let
      (dErrX, x) =
        if error > -dx then (-dy, sx + p.x)
        else (0, p.x)

      (dErrY, y) =
        if error < dy then (dx, sy + p.y)
        else (0, p.y)

      error_ = error + dErrX + dErrY
    in
    bresenhamLineLoop statics error_ (Position x y) positions_
 