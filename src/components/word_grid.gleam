import gleam/list
import gleam/string
import gleam/regex
import lustre/element
import lustre/element/html
import lustre/attribute
import lustre/effect
import shared.{
  guess_max,
  not_word_err,
  too_short_err,
  delay,
  Won,
  Playing,
  Lost,
  Model,
  Pending, 
  GridLetter,
  Correct,
  WrongPos,
  Wrong,
  UserSentGameInput,
  ErrorDelayFinished,
  Closed,
  Open,
  type GridLetter,
  type Model,
  type Msg
}

pub fn update_grid(model: Model, msg: Msg) -> Result(#(Model, effect.Effect(Msg)), Nil) {
    case msg {
        UserSentGameInput(input) -> case model.game_state {
                Playing -> {
                    let new_model = handle_input(model, input)
                    let input_effect = case new_model.error != "" && model.error == "" {
                        True -> delay(1500, ErrorDelayFinished)
                        False -> effect.none()
                    }
                    Ok(#(new_model, input_effect))
                }
                _ -> Ok(#(model, effect.none()))
            }
        _ -> Error(Nil)
    }
}

fn handle_input(model: Model, input: String) {
  let model = Model(..model, error: "")
  case string.length(input), string.length(model.guess) {
    i, _ if i > 1 -> 
      case input {
        "Backspace" -> Model(..model, guess: string.drop_right(model.guess, 1))
        "Enter" -> handle_guess(model)
        _ -> model
      }
    _, g if g < guess_max -> Model(..model, guess: model.guess <> get_alpha(input))
    _, _ -> model
  }
}

fn handle_guess(model: Model) {
  case string.length(model.guess), list.contains(model.words, model.guess) {
    g, True if g == guess_max -> {
        let state = case model.guess == model.word, list.length(model.guesses) + 1 {
            True, _ -> Won
            False, tries if tries == guess_max -> Lost
            _, _ -> Playing
        }
        Model(
            ..model, 
            guess: "",
            guesses: add_new_guess(model.guesses, model.guess, model.word),
            game_state: state,
            end_game_modal: case state {
                Playing -> Closed
                _ -> Open
            }
        )
    }
    g, False if g == guess_max -> Model(..model, error: not_word_err)
    g, _ if g < guess_max -> Model(..model, error: too_short_err)
    _, _ -> model
  }
}

fn add_new_guess(guesses: List(List(GridLetter)), guess: String, word: String) {
  let guess_letters = string.to_graphemes(guess)
  let word_letters = string.to_graphemes(word)

  list.map2(guess_letters, word_letters, fn(g, w) {
    case g, w, string.contains(word, g) {
      g, w, True if g == w -> GridLetter(letter: g, status: Correct)
      _, _, True -> GridLetter(letter: g, status: WrongPos)
      _, _, _ -> GridLetter(letter: g, status: Wrong)
    }
  }) 
  |> fn(g) { [g] }
  |> list.append(guesses, _)
}

fn get_alpha(input: String) {
  let assert Ok(re) = regex.from_string("[a-z]")
  let letter = string.lowercase(input)
  case regex.check(re, letter) {
    True -> letter
    False -> ""
  }
}

fn notification(error: String) -> element.Element(Msg) {
    case error != "" {
        True -> {
            html.div([attribute.class("overlay")], [
                html.div([attribute.class("notification-container")], [element.text(error)])
            ])
        }
        False -> element.none()
    }
}

pub fn word_grid(model: Model) -> element.Element(Msg) {

    let grid_letters: List(List(GridLetter)) = list.concat([
        model.guesses,
        case model.game_state {
            Playing -> [list.append( 
                list.map(string.to_graphemes(model.guess), fn(l) { GridLetter(letter: l, status: Pending) }), 
                list.repeat(GridLetter(letter: "", status: Pending), guess_max - string.length(model.guess)) 
            )]
            _ -> []
        },
        list.repeat(
            list.repeat(GridLetter(letter: "", status: Pending), guess_max),
            guess_max - case model.game_state {
            Playing -> list.length(model.guesses) + 1
            _ -> list.length(model.guesses)
            }
        )
    ])

    html.div([], 
        list.map(grid_letters, fn(row: List(GridLetter)) {
          html.div([attribute.class("grid_row")], 
            list.map(row, fn(g_letter: GridLetter) {
              html.div(list.append([attribute.class("grid_letter_container")], case g_letter.status {
                Correct -> [attribute.class("correct")]
                WrongPos -> [attribute.class("wrong_pos")]
                Wrong -> [attribute.class("wrong")]
                _ -> []
              }), [
                element.text(string.uppercase(g_letter.letter))
              ])
            })
          )
        })
        |> list.prepend(notification(model.error))
    )
}