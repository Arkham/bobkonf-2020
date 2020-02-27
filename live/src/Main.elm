module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attr


type alias Model =
    {}


type Msg
    = NoOp


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( {}, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.text "Hello world!" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
