module Editor where

import Http

import Window
import Dict as D

import Graphics.Input as Input

type Doc = { message : String, extra : Maybe String }

doc : String -> Doc
doc message = { message = message, extra = Nothing }

extraDoc : String -> String -> Doc
extraDoc message extra = { message = message, extra = Just extra }

elmSyntax : D.Dict String Doc
elmSyntax = D.fromList [
             ("=", doc "defining values, pronounced &ldquo;equals&rdquo;"),
             ("\\", doc "anonymous functions, pronounced &ldquo;lambda&rdquo;"),
             (":", doc <| "<a href=\"/learn/Getting-started-with-Types.elm\" target=\"_blank\">" ++
                          "type annotations</a>, pronounced &ldquo;has type&rdquo;"),
             ("->", extraDoc ("&ldquo;function&rdquo; in type annotations <i>or</i> " ++
                              "for control flow in lambdas, cases, and multi-way ifs")
                             (join " "
                              ["<p>When used in a type annotation, an arrow indicates a",
                               "function and is pronounced &ldquo;to&rdquo;. The type",
                               "<code>String -> Int</code> indicates a function from",
                               "strings to integers and is read &ldquo;String to Int&rdquo;.",
                               "You can think of a type like <code>Int -> Int -> Int</code>",
                               "as a function that takes two integer arguments and returns an integer.</p>"])),
             ("<-", doc "updating fields in a record, pronounced &ldquo;gets&rdquo;"),
             ("as", doc "aliasing. Can be used on imported modules and pattern complex patterns."),
             ("let", doc "beginning a let expression"),
             ("in", doc "marking the end of a block of definitions, and starting an expression"),
             ("if", doc "beginning an conditional expression"),
             ("then", doc "separating the first and second branch"),
             ("case", doc "separating the expression to be pattern matched from possible case branches"),
             ("type", doc <| "defining <a href=\"/learn/Pattern-Matching.elm\" target=\"_blank\">" ++
                             "algebraic data types (ADTs)</a>"),
             ("_", doc <| "<a href=\"/learn/Pattern-Matching.elm\" target=\"_blank\">pattern matching</a>" ++
                          " anything, often called a &ldquo;wildcard&rdquo;"),
             ("..", doc "number interpolation"),
             ("|", doc "separating various things, sometimes pronounced &ldquo;where&rdquo;"),
             ("open", doc "showing values on screen, must have type <code>Element</code> or <code>Signal Element</code>"),
             ("import", doc "declaring that a given operator is non-associative"),
             ("infixl", doc "declaring that a given operator is right-associative"),
             ("module", doc "declaring a module definition")]

-- type Module = {
--   name : String,
--   document : String,
--   aliases : [String],
--   datatypes : [Datatype],
--   values : [Value]
-- }

-- type Datatype = { 

-- port rawElmDocs : [Module]

type Token = {
  string : String,
  type_ : TokenType
}

data TokenType = TComment
               | TMeta
               | TString
               | TQualifier
               | TKeyword
               | TVariable
               | TVariable2
               | TVariable3
               | TInteger
               | TNumber
               | TBuiltin
               | TError
               | TNull

type PortableToken = { string : String, type_ : Maybe String }
port pTokens : Signal { string : String, type_ : Maybe String }

toToken : PortableToken -> Token
toToken { string, type_ } = {
  string = string,
  type_ = case type_ of
            Just type' ->
              case type' of
                "comment" -> TComment
                "meta" -> TMeta
                "string" -> TString
                "qualifier" -> TQualifier
                "keyword" -> TKeyword
                "variable" -> TVariable
                "variable-2" -> TVariable2
                "variable-3" -> TVariable3
                "integer" -> TInteger
                "number" -> TNumber
                "builtin" -> TBuiltin
                "error" -> TError
            Nothing -> TNull }

tokens : Signal Token
tokens = toToken <~ pTokens

type Slideable = { string : String, bounds : { top : Int, left : Int, bottom : Int, right : Int } }
type Bounds = { top : Int, left : Int, bottom : Int, right : Int }
port slideables : Signal (Maybe { string : String, bounds : { top : Int, left : Int, bottom : Int, right : Int } })

input : Element
input = [markdown|<textarea id="input" style="width: 100%; height: 100%; margin-bottom: -2em;"></textarea>|]

overlay : Int -> Int -> Maybe Slideable -> Element
overlay w h mSlideable =
  case mSlideable of
    Just { bounds } ->
      container w h (midBottomAt (absolute bounds.left) (absolute (h - bounds.top)))
      <| color blue <| spacer 20 20
    Nothing ->
      empty

top : Int -> Int -> Maybe Slideable -> Element
top w h mSlideable = layers [size w h input, overlay w h mSlideable]

hints : Token -> Element
hints = asText

showHints : Input.Input Bool
showHints = Input.input True

showOptions : Input.Input Bool
showOptions = Input.input False

hotSwap : Input.Input ()
hotSwap = Input.input ()
port hotSwaps : Signal ()
port hotSwaps = hotSwap.signal

compile : Input.Input ()
compile = Input.input ()
port compiles : Signal ()
port compiles = compile.signal

bottom : Bool -> Bool -> Token -> Int -> Element
bottom hint opt t w =
  let hintsEl = if hint then hints t else empty
      showHintsEl = Input.checkbox showHints.handle id hint `beside`
                    plainText "Hints"
      showOptionsEl = Input.checkbox showOptions.handle id opt `beside`
                      plainText "Options"
      leftSideEl = showHintsEl `beside` showOptionsEl
      rightSideEl = flow right [ Input.button hotSwap.handle () "Hot Swap",
                                 Input.button compile.handle () "Compile" ]
      lowerEl = layers [ container w (heightOf rightSideEl) topRight rightSideEl,
                         leftSideEl ]
  in hintsEl `above` lowerEl

bottoms : Signal Element
bottoms = bottom <~ showHints.signal ~ showOptions.signal ~ tokens ~ Window.width

layout : Int -> Int -> Element -> Maybe Slideable -> Element
layout w h btm mSlideable =
  let bottomH = heightOf btm
      topH = h - bottomH
  in top w topH mSlideable `above` btm

main = layout <~ Window.width ~ Window.height ~ bottoms ~ slideables
