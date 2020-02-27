# Rough draft of talk

In my mind the structure of the talk should be divided like this:

- 10 minutes: breaking the ice and introducing Elm and the live coding setup
- 5 minutes: explaining the format of the Nokia ringtone
- 10 minutes: going through how to write a parser using a combinator approach
- 15 minutes: showing web audio API integration and how to connect it to
  the Elm program we've written

## Transcript

Hello everyone! I'm super excited to be here in Berlin! It is a well known
stereotype that it very hard to make German people laugh, so we're going to
perform a controlled experiment to verify such claims. I'm going to read
some jokes and measure your reaction with this laugh-o-meter app.

Let's start with the control case (to be clear, this should not make anyone laugh):

- Javascript is a safe and robust language to design large and complex applications.

Hmm, that's not working... Well, I'm afraid we don't have time for the rest
of the experiment, catch up with me after the talk if you want to hear some
of German jokes I have collected.

Ok then, let's get to the talk!

Today I'm going to show you how to build an application in Elm that can
read and play Nokia 3310 ringtones. You'll going to see the beautiful error
messages that the Elm compiler produces, learn a bit about parser
combinators and, last but not least, the amazing powers of the Web Audio
API. 

And we'll live code most of it!

How many people are familiar with functional programming? How about
statically typed functional programming? (NOTE: depending on the answer, figure
out how much in detail I have to explain things like types and function
signatures).

Let's start with an empty program (I've using this small library called elm
live to live reload the app). I've created some snippets inspired by the
Harry Potter universe.

(Type accioElm, and this appears)

```elm
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
        [ Html.text "Hello World!" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
```

Here's a very typical Elm application:

- First we define that this module is called Main
- Then we import some libraries that we're going to use to display some HTML
- Now in Elm, we follow a pattern of writing applications called Model-View-Update
  - The Model holds the ever-changing data of our application
  - The View takes this Model to generate an HTML view 
  - The Update function is invoked when we want to make a change in our
    Model. It takes it and returns an updated version. In this change you
    can see that the only message is NoOp, and we actually return the
    same model. Don't worry about the weird Cmd Msg part for now.
  - There is a fantastic illustration by @01k about this:
    https://pbs.twimg.com/media/DYImH4mW4AA0SHe?format=jpg&name=4096x4096

Cool, so feel free to interrupt me anytime when you see something that's
too weird. I don't really care about going through all the stuff I've
prepaired, as long as everyone can understand and is following along :>

So, let's try to make a mistake. Instead of writing `Html.text` we happen
to write `Html.tex`. You can see that now our program won't compile and
instead we're shown this error message:

```
I cannot find a `Html.tex` variable:

29|         [ Html.tex "Hello World!" ]
              ^^^^^^^^
The `Html` module does not expose a `tex` variable. These names seem close
though:

    Html.text
    Html.del
    Html.em
    Html.td

Hint: Read <https://elm-lang.org/0.19.1/imports> to see how `import`
declarations work in Elm.
```

And that's the level of error messages you get in Elm. Not only that,
over time you build this feeling that if it compiles it works. You will see
throughout this talk that every time I save and my editor is not
complaining the code will work on the first try.

Something else you'll notice is that I can pretty much type whatever and my
editor will re-format it to look nice. This happens thanks to a beautiful
library called elm-format that is able to read your mind and understand
what type of formatting you want for your code. For example, in this case I
would like to make the code into multiple lines so it reads better: you can
see that elm-format understands that those newlines are something that I
want and readjusts all the code to look good.

Ok cool, now we have our live coding setup figured out, let's look at the
problem again.

A long time ago in a galaxy far, far away, there were no smartphones.
Instead we used to have phones with 84 by 48 pixels monochrome displays.
The Nokia 3310 was announced on 1 September 2000 and it was one of the best
selling phones of that generation. It was marketed towards the youth and
was praised for its durability and resistance.

- https://youtu.be/hXXK6RABUsc?t=90
- https://youtu.be/eCgVgaEYFAM?t=11

One of the amazing features of this phone is that it featured a ringtone
composer. At the time, that was a novel feature! Other phones only allowed
you to download pre-built ringtones and you would have to pay money to be
able to get them. So having a ringtone composer on your phone meant you
could have access to the SOURCE of the ringtone. Pretty cool, eh?

Anyway, here's an example ringtone (accioRingtone):

```elm
ringtone : String
ringtone = "4c2 4d2 4e2 16- 8.#a3"
```

Now we are going to do something called Wishful Programming™. We will
imagine what data structures we could use to describe the problem.

So each tone can either be a sound or a pause. In Elm

```elm
type Tone
    = Sound
    | Pause
```

Also both pitches and pauses can have a duration, expressed as
1, 2, 4, 8, 16, 32:

```elm
type Duration
    = Whole
    | Half
    | Quarter
    | Eighth
    | Sixteenth
    | ThirtySecond
```

To tag this to our tones:

```elm
type Tone
    = Sound Duration
    | Pause Duration
```

Right now, when we need to play a sound we are not really saving anywhere which is the pitch that is being played. A pitch is composed by a note in a certain octave: for example, the note you use to tune a piano is called A4, which is the A note in the fourth octave, which frequency is 440Hz.

```elm
type Pitch
    = Pitch Note Int
```

Having a naked `Int` there works, but it could read better like this

```elm
type alias Octave = Int

type Pitch
    = Pitch Note Octave
```

And what is a note (accioNote)?

```elm
type Note
    = A
    | Bb
    | B
    | C
    | Db
    | D
    | Eb
    | E
    | F
    | Gb
    | G
    | Ab
```

With this we can redefine what a tone is:

```elm
type Tone
    = Sound Pitch Duration
    | Pause Duration
```

Now we have all the data structures we need to store our ringtone.

Or do we?

If we look at our example ringtone we can see this tone:

```
8.#a3
```

What does that dot mean?

In musical notation, a dotted note is a note that lasts half more than the
original note. This means we have to fix our types:

We will rename `Duration` to `DurationLength`:

```elm
type DurationLength
    = Whole
    | Half
    | Quarter
    | Eighth
    | Sixteenth
    | ThirtySecond
```

and create a new `Duration` type

```elm
type Duration
    = Normal DurationLength
    | Dotted DurationLength
```

Notice that the type of `Tone` hasn't changed

```elm
type Tone
    = Sound Pitch Duration
    | Pause Duration
```

Cool, now the only other thing we need is to be able to store the tempo of
our ringtone, which will be expressed in BPM, as Beats per minute.

```elm
type Ringtone
    = Ringtone { tempo : Int
               , tones : List Tone
               }
```

🎉

Cool, now we have described exactly this ideal world that we wished we had.

But unfortunately our real world is still something like this

```elm
ringtone : String
ringtone = "4c2 4d2 4e2 16- 8.#a3"
```

So how do we go from a String to our shiny and beautiful types?

PARSERS!

YES!

PARSERS!

What's a parser? If you think about it, it's a function. You pass a string
and it returns a parsed structure. When you write programs in any language
you end up writing a big string, then a combination of parsers and lexers
and compilers make it possible for your code to run.

First of all we include the dependency (the double dot means import all
functions in the top level namespace):

```
import Parser (..)
```

So the type of our ringtone parser is going to be:

```elm
toneParser : Parser (List Tone)
```

This parser only returns a list of tones, because we can see that the
string itself does not contain information about the tempo of the song.

The most basic parser we can write is a parser that always returns the same
value:

```elm
toneParser : Parser (List Tone)
toneParser =
    Parser.succeed [ Pause (Normal Whole) ]
```

This parser will always return a full pause, no matter the input.

Why is this useful?

When you program with static types it's nice to be able to write something
that compiles first, and then once you're certain that all the pipes are
connected properly, you can go back and replace it with the real implementation.

So how do we run it? The parser library provides a `run` function.

```elm
run : Parser a -> String -> Result (List DeadEnd) a
```

Woah woah woah, let's not panic.

So, we have:

1. A `Parser a`, which basically means a Parser of Something.
2. A String, which we are familiar with.
3. The last part is more interesting. What's a Result?

It's a type that describes an operation that can either succeed or fail. If
you think of your daily life of a programmer, many times it will happen to
save a file and get a huge error message that says syntax error. After you
fix the syntax error, then you will be able to run your code, right?

Well, this type describes exactly that.

```elm
type Result e a =
  Ok a
  Err e
```

So in our case, the result of the parsing can be successful, and we will
get back what we expect, or there will be an error, and we will get back
that weird list of `DeadEnd` types. We don't need to worry about them for
now.

Now let's go back to our view code

```elm
view : Model -> Html Msg
view model =
    let
        result = Parser.run toneParser ringtone
    in
    case result of
        Ok t ->
            Html.div [] [ Html.text (Debug.toString t) ]

        Err e ->
            Html.div [] [ Html.text (Debug.toString e) ]
```

Let's save this. Does it compile? Cool, then I'm 99.99% confident that if we
refresh the browser, the page will load. That's the beauty of working with
a compiler that double checks all your code all the time. It's like the
best friend you never had.

Now let's try to make our parser more useful. For example, let's write a
parser that can parse a single sound.

A sound can be `4c2` (a quarter of C in second octave) or `8.#a3` (an
eighth of A sharp in third octave), so intuitively we know we should be
able to combine two parsers, one for the duration and one for the pitch
itself.

```elm
soundParser : Parser Tone
soundParser =
    Parser.succeed (\duration pitch -> Sound pitch duration)
    |= durationParser
    |= pitchParser
```

That weird `|=` symbol means "consume some input and return a value", which
we can use in the function that we pass to `succeed`. I call it the left
hadouken operator. So let's write a parser for the duration:

```
soundParser : Parser Tone
soundParser =
    let
        durationParser =
            oneOf
                [ succeed (Normal Whole)
                  |. symbol "1"
                , succeed (Normal Half)
                  |. symbol "2"
                ]

        pitchParser = ???
    in
    Parser.succeed (\duration pitch -> Sound pitch duration)
    |= durationParser
    |= pitchParser
```

Here we can see that we use another symbol `|.`, the left pong operator.
This means "consume some input but don't return any value". Why is this
useful? In this case, we don't need any extra information: once we match
"1" we know everything we need.

Let's think about the pitch parser now. A pitch is composed of a note and
an octave. So we need to create another composite parser... I guess if this
has anything to do with that thing.. what was the name.. Parser
combinators!

They sound pretty exoteric, but it just means combining parsers together,
which is exactly what we are doing.

```
soundParser : Parser Tone
soundParser =
    let
        durationParser =
            oneOf
                [ succeed Whole
                  |. symbol "1"
                , succeed Half
                  |. symbol "2"
                ]

        pitchParser =
            succeed (\note octave -> Pitch note octave)
            |= oneOf
                [ succeed C
                  |. symbol "c"
                , succeed D
                  |. symbol "d"
                ]
            |= oneOf
                [ succeed 4
                  |. symbol "1"
                , succeed 5
                  |. symbol "2"
                ]
    in
    Parser.succeed (\duration pitch -> Sound pitch duration)
    |= durationParser
    |= pitchParser
```

Cool, now let's try our parser with some simple input:

```elm
view : Model -> Html Msg
view model =
    let
        result = Parser.run soundParser "2c2"
    in
    case result of
        Ok t ->
            Html.div [] [ Html.text (Debug.toString t) ]

        Err e ->
            Html.div [] [ Html.text (Debug.toString e) ]
```

Amazing, you can see that our parser now reads a String and is able to
understand exactly which sound we are talking about!

And if we pass something that it can't recognize like `dobby` it will print
out this error:

```
[{ col = 1, problem = ExpectingSymbol "1", row = 1 },{ col = 1, problem = ExpectingSymbol "2", row = 1 }]
```

This is the other side of the Result? They are a special type called
`DeadEnd` and it tells you where the parser got stuck. Can you imagine this
level of debugging when a regular expression doesn't match?

I wish I could talk about parsers all day, but I don't have enough time to
go through all the beautiful intricacies of them, so I'll just grab a
complete parser I've written (accioFullParser) and we can see how it looks
on our original ringtone:


```elm
view : Model -> Html Msg
view model =
    let
        result = Parser.run fullParser ringtone
    in
    case result of
        Ok t ->
            Html.div [] [ Html.text (Debug.toString t) ]

        Err e ->
            Html.div [] [ Html.text (Debug.toString e) ]
```

You can see this:

```
[ Sound (Pitch C 6) (Normal Quarter)
, Sound (Pitch D 6) (Normal Quarter)
, Sound (Pitch E 6) (Normal Quarter)
, Pause (Normal Sixteenth)
, Sound (Pitch Bb 7) (Dotted Eighth)
]
```

Our parser has completely understood what the input is. Again, think that
it we did this with a regular expression: we would have been able to match
the same text, but then we would have to use some pretty dirty tricks to
grab each value, and don't get me started on reusing logic in regular
expressions :)

Now that we have a computer program that is able to consume Strings and
turn them into beautiful types, we just need to get these bad boys in the
real world out there.

We are going to use a really powerful web standard called the Web Audio
API. First of all, it's incredibly well supported by all desktop and mobile
browsers. That's as rare as hen's teeth (a hen is a femal chicken, which has
not teeth). You can play around with some amazing demos I will link later.

But first things first.

Everything in the Web Audio API revolves around an Audio Context. So that's
the first thing we are going to create

```js
var audioContext = new AudioContext();
```

Then inside this context, we can have a variety of audio nodes. We will
start with a simple oscillator that generates a simple waveform.

```js
var oscillator = audioContext.createOscillator();
```

Now we can connect it to the audio context destination, so that we can
actually hear something.

```js
oscillator.connect(audioContext.destination);
```

If we play this now, we could achieve a decent cover of John Cage's 4
minutes and 33 seconds (it's a silent piece).

If we actually wanna hear stuff we need to start the oscillator. We'll also
stop it, so that we don't have to listen to it forever. We are going to use
a variable that the context exposes to make sure that the oscillator starts
exactly at the time that we want.

```js
oscillator.start(audioContext.currentTime);

oscillator.stop(audioContext.currentTime + 2);
```

In this case this will play for 2 seconds. Let's try it out!

Really exciting stuff, right?

What if we added another node between the oscillator and the destination?

```js
var filter = audioContext.createBiquadFilter();
```

We just need to hook it up in the right way

```js
oscillator.connect(filter);
filter.connect(audioContext.destination);
```

And then we can tell it to change mid-way

```js
filter.type = "highpass"
filter.frequency.setTargetAtTime(2000, audioContext.currentTime + 1, 1);
```

That sounds soo cool already!

Ok, enough monkeying around, let's get back to business.

I've built a slightly nicer example with some CSS, so let's switch to that.
I've also replaced our implementation of the ringtone parser with a library
I've written which handles all the edge cases of the format. It's really
similar to our old one, so it shouldn't look too unfamiliar.

(New code)
```elm
module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Encode as Encode
import RTTL


type alias Model =
    { userInput : String
    , alertMessage : String
    }


type Msg
    = UserInput String
    | Play


initialModel : Model
initialModel =
    { userInput = "32c2 32f2 32c2 32f2 4c2 8#g1 8#a1 4f1 8- 32c2 32f2 32c2 32f2 4c2 8#g1 8#a1 4#d2 8- 32c2 32- 32#d2 4f2 16#g2 32- 16g2 32- 32f2 32- 4#d2 8- 32c2 32f2 32c2 32f2 4c2 8#a1 4f1"
    , alertMessage = ""
    }


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


view : Model -> Html Msg
view model =
    Html.div [ Attr.class "container" ]
        [ Html.h1 [] [ Html.text "NOKIA" ]
        , Html.textarea
            [ Attr.id "nokia-composer"
            , Attr.value model.userInput
            , Events.onInput UserInput
            ]
            []
        , Html.button [ Events.onClick Play ] [ Html.text "Play" ]
        , Html.text model.alertMessage
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserInput newInput ->
            ( { model | userInput = newInput }, Cmd.none )

        Play ->
            case RTTL.parseComposer { tempo = 64 } model.userInput of
                Ok value ->
                    ( { model | alertMessage = Debug.toString value }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | alertMessage = "Could not parse ringtone, sorry!" }, Cmd.none )
```

As you can see, not much has changed. We have our ringtone saved as a
String and we run `RTTL.parseComposer` to parse it into nice Elm types.

If we check our new update function we can see we have two messages:
- one for updating the user input
- one for playing the ringtone

In order to communicate with the outside world, we need to convert
something like `Sound (Pitch C 6) (Normal Quarter)` to a format that the
web audio api will understand.

A good representation could be something like:

```js
{ frequency : Float
, duration : Float
}
```

That's quite easy, but a bit boring so I won't re-implement it now. You can
check it out here: https://github.com/Arkham/elm-rttl/blob/master/src/RTTL.elm#L162

The important part is to understand the signature of the function:

```elm
encode : Ringtone -> Encode.Value
```

You can see that I take the nice Elm types and I transform them into a JSON
blob. Once we have that data in a nice format, we need to send it out. Elm has a
mechanism for communicating with the outside world called Ports.

So I change the top of the file to read:

```elm
port module Main exposing (main)
```

And I add a port

```elm
port sendRingtone : Json.Value -> Cmd msg
```

Uh, what's that `Cmd msg` thingy? Let's look at the shape of our `update`
function:

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
```

If you were still awake at the beginning of the talk I said that didn't
have to worry about that weird `Cmd Msg`. Well, I lied.

Elm is a pure language, which means that everytime you run a function and
you pass the same arguments you will get the same return values. But that
guarantee doesn't work well in the real world. Imagine when you write
'print "hello"': what's the return value of that function?

So the way that you represent these side effects in Elm is using these
commands. Don't worry if you don't understand all of this, you really don't
need to :)

What we are going to do is to create a Command which will send the data
over the port. In this section

```
case RTTL.parseComposer { tempo = 64 } model.userInput of
    Ok value ->
        ( { model | alertMessage = Debug.toString value }
        , Cmd.none
        )
```

We can replace `Cmd.none` with `sendRingtone (RTTL.encode value)`. Now
this value will be sent to the javascript side of things, that can listen
for messages of this type:

```js
var app = Elm.Main.init({ node: document.querySelector('main') })

app.ports.sendRingtone.subscribe(function(data) {
  console.log(data);
});
```

Let's try it out! 🎸

Awesome, now all that's left to do is to play the notes that we are
parsing.

```js
app.ports.sendRingtone.subscribe(function(data) {
  var context = new AudioContext();

  data.reduce(function(now, elem) {
    oscillator = context.createOscillator();
    oscillator.connect(context.destination);
    oscillator.frequency.value = elem.frequency;

    oscillator.start(context.currentTime + now);
    oscillator.stop(context.currentTime + now + elem.duration - 0.002);

    return(now + elem.duration);
  }, 0);
});
```

You should be familiar with everything here:
- we go through the list of notes
- we create a new oscillator and connect it to the destination
- we change the frequency to the desired frequency
- we play it for the correct duration

The only small trick is that we keep a counter of the exact time that we
want each note to start at. So, in a way, we are shooting all the notes at
once, but they will start playing at the exact right time and stop at the
exact right time.

Let's try this out!

This doesn't sound bad but it doesn't really give that 90s Nokia vibe. If
we go and look the MDN documentation about the OscillatorNode we can see
that by default this node supports the following waves:

- sine
- square
- sawtooth
- triangle
- custom

Custom? That sounds interesting...

Apparently you can create a waveform by passing two arrays, one of real
numbers and one of imaginary numbers, that describe the waveform.

```js
var wave = context.createPeriodicWave(real, imag);
```

Then you can set an oscillator to use such wave:

```js
oscillator.setPeriodicWave(wave);
```

So imagine someone bought an original Nokia 3310, sampled the sound, then
did some quick Fourier Transforms to convert the original signal to the
list of imaginary and real required by the Web Audio API and you will get
these:

```js
var real = new Float32Array([0.26, 0.36, 0.57, 0.84, 1, 0.79, 0.72, 0.76, 0.82, 0.84, 0.64, 0.35, 0.12, 0.19, 0.23, 0.21, 0.08, 0.10, 0.17, 0.27, 0.22, 0.20, 0.22, 0.15, 0.13, 0.12, 0.11, 0.11, 0.10, 0.09, 0.09, 0.08, 0.08, 0.07, 0.08, 0.06, 0.04, 0.03, 0.02, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0, 0]);
var imag = new Float32Array(64);
imag.fill(0);
```

Cool, let's try it now :)

Load up demo with ringtones and play some. The end!

## Demo

https://ellie-app.com/86DCyYXWTCya1

## TODO (these points are flexible once I try the talk, will add if time allows)

- use gain nodes to regulate oscillators instead of creating and throwing away oscillators
- explain how to stop the melody and play it again
- add some filters that change the sound while playing the ringtones
