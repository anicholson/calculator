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
    , clearDisplayOnNextInput : Bool
    , error : Bool
    , styles : ClassNames
    }


type Msg
    = ClearAll
    | EnteredDigit Digit
    | EnteredDecimal
    | EnteredBinaryOperator BinaryOperator
    | EnteredUnaryOperator UnaryOperator
    | Equals


blankModel : ClassNames -> Model
blankModel styles =
    { stack = 0.0, currentInput = [], activeOperator = Nothing, error = False, styles = styles, clearDisplayOnNextInput = True }


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
    let
        floatToChars =
            String.toList << toString
    in
        Just
            { model
                | stack = answer
                , currentInput = floatToChars answer
                , activeOperator = Nothing
                , error = False
                , clearDisplayOnNextInput = True
            }


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
                -- throw away the input iff there's a value stacked exists, or no operation has been stashed
                let
                    newInputValue =
                        if model.clearDisplayOnNextInput then
                            [ d ]
                        else
                            List.append model.currentInput [ d ]
                in
                    if isDigit d then
                        ( { model | currentInput = newInputValue, clearDisplayOnNextInput = False }, Cmd.none )
                    else
                        nothingHappens

            EnteredDecimal ->
                if alreadyDecimal model.currentInput then
                    nothingHappens
                else
                    let
                        newInputValue =
                            if model.clearDisplayOnNextInput then
                                [ '0', '.' ]
                            else
                                List.append model.currentInput [ '.' ]
                    in
                        ( { model | currentInput = newInputValue, clearDisplayOnNextInput = False }, Cmd.none )

            EnteredBinaryOperator o ->
                case model.activeOperator of
                    Nothing ->
                        case inputAsNumber model.currentInput of
                            Just number ->
                                ( { model | activeOperator = Just o, stack = number, clearDisplayOnNextInput = True }, Cmd.none )

                            Nothing ->
                                errorOut

                    otherwise ->
                        errorOut

            EnteredUnaryOperator o ->
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
                            let
                                wev =
                                    Debug.log "error" whyNot
                            in
                                errorOut


digitButton : String -> Digit -> Html.Html Msg
digitButton className digit =
    div [ class className, onClick <| EnteredDigit digit ] [ text <| String.fromChar digit ]


actionButton : String -> String -> Msg -> Html.Html Msg
actionButton className caption msg =
    div [ class className, onClick msg ] [ text caption ]


digitButtons : ClassNames -> Html.Html Msg
digitButtons s =
    div [ class s.numbers ]
        [ div [ class s.numbersContainer ]
            [ div [ class s.buttonRow ]
                [ digitButton s.digitButton '7'
                , digitButton s.digitButton '8'
                , digitButton s.digitButton '9'
                ]
            , div [ class s.buttonRow ]
                [ digitButton s.digitButton '4'
                , digitButton s.digitButton '5'
                , digitButton s.digitButton '6'
                ]
            , div [ class s.buttonRow ]
                [ digitButton s.digitButton '1'
                , digitButton s.digitButton '2'
                , digitButton s.digitButton '3'
                ]
            , div [ class s.buttonRow ]
                [ digitButton s.bigDigitButton '0'
                , actionButton s.actionButton "." EnteredDecimal
                ]
            ]
        ]


actionButtons : ClassNames -> Html.Html Msg
actionButtons s =
    div [ class s.actions ]
        [ actionButton s.actionButton "+" <| EnteredBinaryOperator Plus
        , actionButton s.actionButton "−" <| EnteredBinaryOperator Minus
        , actionButton s.actionButton "×" <| EnteredBinaryOperator Multiply
        , actionButton s.actionButton "÷" <| EnteredBinaryOperator Divide
        , actionButton s.actionButton "=" Equals
        ]


view model =
    let
        s =
            model.styles
    in
        div [ class s.container ]
            [ div [ class s.display ] [ section [] [ section [] [ text <| String.fromList model.currentInput ] ] ]
            , div [ class s.buttons ] [ digitButtons s, actionButtons s ]
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
