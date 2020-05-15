port module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Html exposing (Attribute, Html, a, br, button, div, h1, h2, img, input, label, pre, span, text)
import Html.Attributes exposing (class, href, placeholder, src, style, value, width)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode
import Markdown exposing (defaultOptions)
import Set exposing (Set)
import Svg exposing (svg)
import Svg.Attributes as SvgAttribs exposing (clipRule, d, fill, fillRule, height, stroke, strokeLinejoin, strokeMiterlimit, viewBox)
import Time exposing (Posix, customZone, millisToPosix, toHour, toMinute)
import Url.Builder



-- MAIN


hinweis : Html msg
hinweis =
    Markdown.toHtmlWith markdownOptions [ class "f5-l f6 i lh-copy ph2 ph1-l " ] """Hier könnte eine Hinweis stehen."""



main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { disclaimerOpen : Bool
    , question : String
    , rawAnswers : String
    , answers : List Answer
    , answerProblems : String
    , images : Dict String String
    , selected : List Answer
    , phoneOpen : Bool
    , time : Int -- posix millis
    , utcOffset : Int -- in minutes
    , strings : Dict String String
    }


decodeModel =
    Decode.succeed Model
        |> hardcoded False
        |> optional "stichwort" Decode.string "hallo"
        |> required "answers" Decode.string
        |> hardcoded []
        |> hardcoded ""
        |> required "images" (Decode.dict Decode.string)
        |> hardcoded []
        |> optional "startOpen" Decode.bool False
        |> optional "time" Decode.int 0
        |> optional "utcOffset" Decode.int 0
        |> optional "strings" (Decode.dict Decode.string) Dict.empty



-- (Decode.map millisToPosix Decode.int) (millisToPosix 0)


type alias Answer =
    { name : String
    , triggerWords : Set String
    , title : String
    , text : String
    }


dropWhile : (a -> Bool) -> List a -> List a
dropWhile predicate items =
    case items of
        [] ->
            []

        h :: t ->
            if predicate h then
                dropWhile predicate t

            else
                h :: t


fuchsParse : String -> Result String (List Answer)
fuchsParse s =
    let
        sections =
            String.split
                "\n---"
                s

        innerSub pre post str =
            String.slice 0 pre str ++ " ... " ++ String.slice (-1 * post) -1 str

        parseSection sec =
            let
                parts =
                    String.split "\n--" sec
            in
            case parts of
                [ question, answer ] ->
                    case dropWhile (String.isEmpty << String.trim) <| String.lines question of
                        triggers :: rest ->
                            Ok <| Answer "" (Set.fromList <| String.words <| String.toLower triggers) (String.join "\n" rest) answer

                        _ ->
                            Err ("Frage zu kurz: " ++ question)

                [] ->
                    Err "Leerer Abschnitt? (Nichts Verwertbares zwischen zwei '---'?)"

                [ fehlerblock ] ->
                    Err <| "Keine Trenner im Abschnitt? (Kein '--' zwischen '---'?) Bei " ++ innerSub 10 10 fehlerblock

                _ ->
                    Err "Mehr als einmal '--' zwischen zwei '---'?"

        sectionFolder sec l =
            case l of
                Ok items ->
                    case parseSection sec of
                        Ok a ->
                            Ok (a :: items)

                        Err problem ->
                            Err problem

                Err problem ->
                    Err problem

        -- this is can be nicer with andThen... but I cant wrap my head around it right now
    in
    List.foldl sectionFolder (Ok []) sections


decodeAnswer =
    Decode.succeed Answer
        |> required "title" Decode.string
        |> (required "trigger" <| Decode.map Set.fromList <| Decode.list Decode.string)
        |> required "text" Decode.string
        |> (required "trigger" <| Decode.map (List.head >> Maybe.withDefault "") <| Decode.list Decode.string)


renderTime : Int -> Int -> String
renderTime utcOffset millis =
    let
        hereZone =
            customZone utcOffset []

        posixTime =
            millisToPosix millis

        hours =
            toHour hereZone posixTime |> String.fromInt

        minutes =
            toMinute hereZone posixTime |> String.fromInt |> String.pad 2 '0'
    in
    hours ++ ":" ++ minutes


init : Decode.Value -> ( Model, Cmd Msg )
init value =
    ( case Decode.decodeValue decodeModel value of
        Err _ ->
            Model False "" "" [] "" Dict.empty [] False 0 0 Dict.empty

        Ok m ->
            case fuchsParse m.rawAnswers of
                Ok aws ->
                    let
                        newModel =
                            { m | answers = aws }
                    in
                    { newModel | selected = findAnswers newModel.answers newModel.question }

                Err problem ->
                    { m | answerProblems = problem }
    , Cmd.none
      --, Http.get
      --    { url = "https://elm-lang.org/assets/public-opinion.txt"
      --    , expect = Http.expectString GotText
      --    }
    )



-- UPDATE


type Msg
    = QuestionInput String
    | ToggleDisclaimer
    | ExternalChange Encode.Value
    | ClosePhone
    | OpenPhone
    | TimeChanged Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        QuestionInput s ->
            let
                newModel =
                    { model | question = s, selected = findAnswers model.answers s }

                cmd =
                    case newModel.selected of
                        [] ->
                            Cmd.none

                        _ :: _ ->
                            updateStichwort <| Encode.string newModel.question
            in
            ( newModel, cmd )

        ToggleDisclaimer ->
            ( { model | disclaimerOpen = not model.disclaimerOpen }, Cmd.none )

        ExternalChange v ->
            case Decode.decodeValue Decode.string v of
                Err _ ->
                    ( model, Cmd.none )

                Ok s ->
                    update (QuestionInput <| s) model

        ClosePhone ->
            ( { model | phoneOpen = False }, Cmd.none )

        OpenPhone ->
            ( { model | phoneOpen = True }, Cmd.none )

        TimeChanged millis ->
            ( { model | time = millis }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ stichwortChanged ExternalChange, timeChanged TimeChanged ]


getDefault : String -> Dict String String -> String -> String
getDefault key dict dflt =
    case Dict.get key dict of
        Nothing ->
            dflt

        Just thing ->
            thing


ortseingang strings attribs =
    svg ([ viewBox "0 0 720 500", fill "currentcolor", SvgAttribs.width "200px", SvgAttribs.class "ortseingang pa1 center db" ] ++ attribs)
        [ Svg.path [ d "M30,480C30,480 0.023,480.008 0,450L0,30C0,30 -0.082,0 30,0L690,0C720.082,0 720,30 720,30L720,450C719.977,480.008 690,480 690,480L30,480Z", SvgAttribs.fill "rgb(240,201,0)" ] []
        , Svg.path [ d "M30,472C30,472 8.012,471.961 8,450L8,30C8,30 7.992,7.98 30,8L690.074,8C712.082,7.98 712.074,30 712.074,30L712.074,450C712.063,471.961 690.074,472 690.074,472L30,472ZM30,460L690.074,460C690.074,460 700.016,459.996 700.035,450C700.926,312.348 700.211,30 700.211,30C700.176,20.27 690.074,20 690.074,20L30,20C30,20 19.898,20.27 19.859,30C19.859,30 19.148,312.348 20.039,450C20.055,459.996 30,460 30,460Z" ] []
        , Svg.text_ [ SvgAttribs.x "50%", SvgAttribs.y "40%", SvgAttribs.class "topline", SvgAttribs.dominantBaseline "middle", SvgAttribs.textAnchor "middle" ] [ Svg.text <| getDefault "ortsname" strings "Wüstefeld" ]
        , Svg.text_ [ SvgAttribs.x "50%", SvgAttribs.y "65%", SvgAttribs.class "bottomline", SvgAttribs.dominantBaseline "middle", SvgAttribs.textAnchor "middle" ] [ Svg.text <| getDefault "ortstitel" strings "Glasfaserdorf " ]
        ]



-- VIEW
-- A `Json.Decoder` for grabbing `event.target.currentTime`.


view : Model -> Html Msg
view model =
    let
        fuchsphone =
            div [ class "fuchsphone cl bg-fuchs  pa3" ]
                [ div [ class "statushead  flex justify-between tracked " ]
                    [ div [] [ text <| getDefault "carrier_name" model.strings "FUCHS"  ]
                    , div [] [ text <| renderTime model.utcOffset model.time ]
                    , div [ class "f6" ] [ text "●●●●" ]
                    ]
                , div [ class "chathead ph4 pb2 flex items-center " ]
                    [ img [ class "h3 w3 ", src <| imageURI model "glafaavatar" ] []
                    , div [ class "flex-grow pl2 gray", style "flex-grow" "1" ] [ span [ class "b f4" ] [ text "Glasfaserfuchs" ], br [] [], span [ class "green-pulse i f6" ] [ text <| "online in " ++ getDefault "ortsname" model.strings "Wüstefeld" ] ]
                    ]
                , div [ class "fuchsphone-content" ]
                    [ viewAnswer model
                    ]
                , div [ class "chatschlitz pa2" ]
                    [ label [ class "black-70 b pa2" ] [ text "Stichwort oder Frage:", br [] [], input [ onInput QuestionInput, value model.question, placeholder <| getDefault "platzhalter" model.strings "vong Glasfaser her", class "pa2 ma2 w-90" ] [] ] ]
                , button [ class "fuxit pointer db", onClick ClosePhone ] [ crossIcon ]
                ]

        fuchsbutton =
            button [ onClick OpenPhone, class "db pa1 mv2 flex-l link justify-around items-center fuchsbutton pointer tl" ]
                [ img [ class "h4 w4 db center", src <| imageURI model "fuchs" ] []
                , div [ class "pa4" ]
                    [ div [ class "b f3 black-90 pa2" ] [ text <| getDefault "knopftitel" model.strings "Frag den Fuchs!" ]
                    , div [ class "f5 black-70 pa2" ] [ text <| getDefault "knopftext" model.strings "Der Glasfaserfuchs hilft Dir bei Deinen Fragen zum Projekt in Wüstefeld" ]
                    ]
                , ortseingang model.strings []
                ]

        fuchsprobleme =
            pre [] [ text model.answerProblems ]
    in
    div [ class "fuchsbau relative sans-serif ma1   " ]
        [ case model.disclaimerOpen of
            True ->
                div [ class "modal-middle bg-white pa5-l pa1 no-print", onClick ToggleDisclaimer ] [ hinweis, div [ class "tc" ] [ div [ class "f6 grow no-underline br-pill ph3 pv2 mb2 dib bg-light-gray dark-blue ttc b tracked  mt3" ] [ text "Alles klar!" ] ] ]

            False ->
                text ""
        , if model.phoneOpen then
            div []
                [ div [ class "fuchsvorhang" ] []
                , fuchsphone
                ]

          else if String.length model.answerProblems > 0 then
            fuchsprobleme

          else
            fuchsbutton
        ]


imageURI : Model -> String -> String
imageURI model name =
    Maybe.withDefault "" <| Dict.get name model.images


viewFuchs : Model -> Html Msg
viewFuchs model =
    div [ class "mv2 black-90  pa2" ] <|
        [ h1 [ class "f2-l f3 normal i mv0" ] [ text "Der Glasfaserfuchs weiß Bescheid!" ]
        , h2 [ class "f3-l f4 normal mv2 " ] [ text "Gib ihm ein Stichwort oder stelle ihm eine Frage:" ]
        , Markdown.toHtmlWith markdownOptions [ class "f5 bold-links lh-copy" ] "z.B. [Vertrag](#vertrag), [Kosten](#kosten), [Tiefbau](#tiefbau), [Wie viele Veträge?](#status), [Wie geht die Verkabelung im Haus?](#verkabelung), [Wo ist der Sammelbriefkasten?](#briefkasten) ..."
        , input [ onInput QuestionInput, class "f2-l f3 pa2 w-90", placeholder "Stichwort oder Frage", value model.question ] []
        ]


checkTrigger : String -> Set String -> Bool
checkTrigger s words =
    let
        qwords =
            Set.fromList <| List.map String.toLower <| String.words <| String.filter (\c -> not <| String.contains (String.fromChar c) ".,?;!@&^%") s
    in
    not <| Set.isEmpty <| Set.intersect words qwords


isRelevantAnswer : String -> Answer -> Bool
isRelevantAnswer q a =
    case q of
        "" ->
            False

        raws ->
            let
                s =
                    String.trim raws
            in
            (s == a.title) || checkTrigger s a.triggerWords


findAnswers : List Answer -> String -> List Answer
findAnswers answers question =
    case question of
        "" ->
            List.filter (isRelevantAnswer "hallo") answers

        _ ->
            List.filter (isRelevantAnswer question) answers


markdownOptions =
    { defaultOptions | sanitize = False, smartypants = True }


renderAnswer : Model -> Answer -> Bool -> Html Msg
renderAnswer model answer renderFox =
    let
        questionBubble =
            case answer.title of
                "" ->
                    text ""

                _ ->
                    div [ class "cb flex items-center mb3 " ]
                        [ div
                            [ class "speech-bubble-right pa3 ph2 w-95 mr3 pa2" ]
                            [ div [ class "" ]
                                [ Markdown.toHtmlWith markdownOptions [ class "f5-l f6 lh-copy bold-links" ] answer.title ]
                            ]

                        -- , img [ class "w-10 pa2 w-20-l", src <| imageURI model "person" ] []
                        ]

        fuchsBubble =
            div [ class "cb flex items-center" ]
                [ --
                  div
                    [ class <|
                        "speech-bubble-left pa1 ph2 w-95 ml4"
                            ++ (if renderFox then
                                    " bottom-speech"

                                else
                                    " left-speech"
                               )
                    ]
                    [ Markdown.toHtmlWith markdownOptions [ class "f5-l f6  lh-copy bold-links" ] answer.text
                    , if renderFox then
                        img [ class "w-20-l w-10 pa2 glasfaserfuchs", src <| imageURI model "fuchs" ] []

                      else
                        text ""

                    --, div [ class "tc f6 i" ] [ text "Angaben ohne Gewähr", br [] [], a [ class "f6 grow no-underline br-pill ph3 pv2 mb2 dib bg-light-gray dark-blue ttc b tracked  mt3", onClick ToggleDisclaimer ] [ text "Hinweis anzeigen" ] ]
                    --, hr [] []
                    -- , div [ class "tc" ] [ whatsAppShare model answer ]
                    ]
                ]
    in
    div [ class "mb3" ]
        [ questionBubble
        , fuchsBubble
        ]


allWords : Model -> Set String
allWords model =
    List.foldl (.triggerWords >> Set.union) Set.empty model.answers


createWordLinks : Set String -> String
createWordLinks words =
    String.join ", " <| Set.toList <| Set.map (\w -> "[" ++ (String.toUpper <| String.left 1 w) ++ String.dropLeft 1 w ++ "](#" ++ w ++ ")") <| Set.filter (String.startsWith "_" >> not) words


extraAnswers : Model -> List Answer
extraAnswers model =
    let
        replaceSpecials a =
            { a | text = String.replace "$ALLEWÖRTER$" (createWordLinks <| allWords model) a.text }
    in
    List.map replaceSpecials <| findAnswers model.answers "_extra"





whatsAppShare : Model -> Answer -> Html Msg
whatsAppShare _ answer =
    a [ class "white bg-green v-mid pa3 dib link inline-flex items-center ba bw1 b--dark-green br3", href (Url.Builder.custom (Url.Builder.CrossOrigin "https://wa.me") [] [ Url.Builder.string "text" (answer.title ++ " Der Glasfaserfuchs weiß es: https:///?gff#" ++ answer.name) ] Nothing) ]
        [ svg [ viewBox "0 0 24 24", SvgAttribs.width "16", fill "white", stroke "white", height "16", fillRule "evenodd", clipRule "evenodd", strokeLinejoin "round", strokeMiterlimit "1.414" ] [ Svg.path [ fillRule "nonzero", d "M17.498 14.382c-.301-.15-1.767-.867-2.04-.966-.273-.101-.473-.15-.673.15-.197.295-.771.964-.944 1.162-.175.195-.349.21-.646.075-.3-.15-1.263-.465-2.403-1.485-.888-.795-1.484-1.77-1.66-2.07-.174-.3-.019-.465.13-.615.136-.135.301-.345.451-.523.146-.181.194-.301.297-.496.1-.21.049-.375-.025-.524-.075-.15-.672-1.62-.922-2.206-.24-.584-.487-.51-.672-.51-.172-.015-.371-.015-.571-.015-.2 0-.523.074-.797.359-.273.3-1.045 1.02-1.045 2.475s1.07 2.865 1.219 3.075c.149.195 2.105 3.195 5.1 4.485.714.3 1.27.48 1.704.629.714.227 1.365.195 1.88.121.574-.091 1.767-.721 2.016-1.426.255-.705.255-1.29.18-1.425-.074-.135-.27-.21-.57-.345m-5.446 7.443h-.016c-1.77 0-3.524-.48-5.055-1.38l-.36-.214-3.75.975 1.005-3.645-.239-.375c-.99-1.576-1.516-3.391-1.516-5.26 0-5.445 4.455-9.885 9.942-9.885 2.654 0 5.145 1.035 7.021 2.91 1.875 1.859 2.909 4.35 2.909 6.99-.004 5.444-4.46 9.885-9.935 9.885M20.52 3.449C18.24 1.245 15.24 0 12.045 0 5.463 0 .104 5.334.101 11.893c0 2.096.549 4.14 1.595 5.945L0 24l6.335-1.652c1.746.943 3.71 1.444 5.71 1.447h.006c6.585 0 11.946-5.336 11.949-11.896 0-3.176-1.24-6.165-3.495-8.411 " ] [] ]
        , span [ class "mh2" ] [ text "per WhatsApp teilen" ]
        ]


crossIcon =
    svg [ viewBox "0 0 32 32", fill "currentcolor", SvgAttribs.width "32", SvgAttribs.height "32" ]
        [ Svg.path [ d "M4 8 L8 4 L16 12 L24 4 L28 8 L20 16 L28 24 L24 28 L16 20 L8 28 L4 24 L12 16 z" ] [] ]


viewAnswer : Model -> Html Msg
viewAnswer model =
    case model.selected of
        [] ->
            div [ class "w100 tc" ]
                [ img [ src <| imageURI model "loading", width 160 ] []
                , div [ class "f6 white-50" ] [ text (String.fromInt <| List.length model.answers) ]
                ]

        aas ->
            let
                answers =
                    aas
                        ++ (if model.question /= "" then
                                extraAnswers model

                            else
                                []
                           )

                answerCount =
                    List.length answers
            in
            div [ class "black-70" ] <|
                List.indexedMap (\i a -> renderAnswer model a (i == answerCount - 1)) answers


port updateStichwort : Encode.Value -> Cmd msg


port stichwortChanged : (Encode.Value -> msg) -> Sub msg


port timeChanged : (Int -> msg) -> Sub msg
