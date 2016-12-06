module Calculator exposing (..)

import Html exposing (programWithFlags, text, div, section)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Char exposing (isDigit)
import Result exposing (andThen)
import Styles exposing (ClassNames)


type alias Digit =
    Char


type BinaryOperator
    = Plus
    | Minus
    | Multiply
    | Divide


type UnaryOperator
    = SquareRoot


type alias Model =
    { stack : Float
    , currentInput : List Digit
    , activeOperator : Maybe BinaryOperator
    , error : Bool
    , styles : ClassNames
    }


type Msg
    = ClearAll
    | EnteredDigit Digit
    | EnteredDecimal
    | BinaryOperator BinaryOperator
    | UnaryOperator UnaryOperator
    | Equals


blankModel : ClassNames -> Model
blankModel styles =
    { stack = 0.0, currentInput = [], activeOperator = Nothing, error = False, styles = styles }


init : ClassNames -> ( Model, Cmd msg )
init styles =
    ( blankModel styles, Cmd.none )


alreadyDecimal : List Digit -> Bool
alreadyDecimal digits =
    let
        isDecimalPoint =
            \c -> c == '.'

        single =
            \list -> List.length list == 1
    in
        single <| List.filter isDecimalPoint digits


inputAsNumber : List Digit -> Maybe Float
inputAsNumber digits =
    let
        stringForm =
            String.fromList digits
    in
        case String.toFloat stringForm of
            Ok f ->
                Just f

            Err _ ->
                Nothing


placeAnswerInModel : Model -> Float -> Maybe Model
placeAnswerInModel model answer =
    Just { model | stack = answer, currentInput = [], activeOperator = Nothing, error = False }


performUnaryOperation : UnaryOperator -> Model -> Result String Model
performUnaryOperation operator model =
    let
        extractInput =
            inputAsNumber model.currentInput

        applyOperation =
            case operator of
                SquareRoot ->
                    \i -> Just (i ^ 0.5)

        result =
            extractInput
                |> Maybe.andThen applyOperation
                |> Maybe.andThen (placeAnswerInModel model)
    in
        Result.fromMaybe "Unable to perform operation" result


performBinaryOperation : Model -> Result String Model
performBinaryOperation model =
    let
        left =
            model.stack

        extractRightOperand =
            inputAsNumber model.currentInput

        applyOperation =
            case model.activeOperator of
                Just Plus ->
                    \right -> Just (left + right)

                Just Minus ->
                    \right -> Just (left - right)

                Just Multiply ->
                    \right -> Just (left * right)

                Just Divide ->
                    \right -> Just (left / right)

                Nothing ->
                    always Nothing

        result =
            extractRightOperand
                |> Maybe.andThen applyOperation
                |> Maybe.andThen (placeAnswerInModel model)
    in
        Result.fromMaybe "Unable to perform operation" result


seeIfRightOperandMissing model =
    if List.isEmpty model.currentInput then
        Err "no second number"
    else
        Ok model


seeIfInputParseable model =
    case inputAsNumber model.currentInput of
        Just _ ->
            Ok model

        Nothing ->
            Err "can't understand second number"


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    let
        nothingHappens =
            ( model, Cmd.none )

        errorOut =
            ( { model | error = True }, Cmd.none )
    in
        case msg of
            ClearAll ->
                init model.styles

            EnteredDigit d ->
                if isDigit d then
                    ( { model | currentInput = List.append model.currentInput [ d ] }, Cmd.none )
                else
                    nothingHappens

            EnteredDecimal ->
                if alreadyDecimal model.currentInput then
                    nothingHappens
                else
                    ( { model | currentInput = List.append model.currentInput [ '.' ] }, Cmd.none )

            BinaryOperator o ->
                case model.activeOperator of
                    Just _ ->
                        case inputAsNumber model.currentInput of
                            Just number ->
                                ( { model | activeOperator = Just o, stack = number }, Cmd.none )

                            Nothing ->
                                errorOut

                    otherwise ->
                        errorOut

            UnaryOperator o ->
                let
                    result =
                        seeIfRightOperandMissing model
                            |> andThen seeIfInputParseable
                            |> andThen (performUnaryOperation o)
                in
                    case result of
                        Ok finalModel ->
                            ( finalModel, Cmd.none )

                        Err whyNot ->
                            errorOut

            Equals ->
                let
                    seeIfBlank =
                        \model ->
                            if model == blankModel model.styles then
                                Err "Nothing to do"
                            else
                                Ok model

                    result =
                        seeIfBlank model
                            |> andThen seeIfRightOperandMissing
                            |> andThen seeIfInputParseable
                            |> andThen performBinaryOperation
                in
                    case result of
                        Ok finalModel ->
                            ( finalModel, Cmd.none )

                        Err whyNot ->
                            errorOut


digitButton : String -> Digit -> Html.Html Msg
digitButton className digit =
    div [ class className, onClick <| EnteredDigit digit ] [ text <| String.fromChar digit ]


actionButton : String -> String -> Msg -> Html.Html Msg
actionButton className caption msg =
    div [ class className, onClick msg ] [ text caption ]


view model =
    let
        s =
            model.styles
    in
        div [ class s.container ]
            [ div [ class s.display ] [ section [] [ section [] [ text <| String.fromList model.currentInput ] ] ]
            , div [ class s.buttons ]
                [ div [ class s.numbers ]
                    [ div [ class s.numbersContainer ]
                        [ div [ class s.buttonRow ]
                            [ digitButton s.button '7'
                            , digitButton s.button '8'
                            , digitButton s.button '9'
                            ]
                        , div [ class s.buttonRow ]
                            [ digitButton s.button '4'
                            , digitButton s.button '5'
                            , digitButton s.button '6'
                            ]
                        , div [ class s.buttonRow ]
                            [ digitButton s.button '1'
                            , digitButton s.button '2'
                            , digitButton s.button '3'
                            ]
                        , div [ class s.buttonRow ]
                            [ digitButton s.bigButton '0'
                            , actionButton s.button "." EnteredDecimal
                            ]
                        ]
                    ]
                ]
            ]


subscriptions _ =
    Sub.none


main =
    programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
