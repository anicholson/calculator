module Styles exposing (ClassNames, decoder)

import Json.Decode as Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (decode, required)


type alias ClassNames =
    { container : String
    , display : String
    , digitButton : String
    , buttons : String
    , bigDigitButton : String
    , numbers : String
    , numbersContainer : String
    , buttonRow : String
    , actions : String
    , actionButton : String
    }


decoder : Decoder ClassNames
decoder =
    decode ClassNames
        |> required "container" string
        |> required "display" string
        |> required "button" string
        |> required "buttons" string
        |> required "bigButton" string
        |> required "numbers" string
        |> required "numbersContainer" string
        |> required "buttonRow" string
        |> required "actions" string
        |> required "actionButton" string
