import components/keyboard.{keyboard}
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/pair
import gleam/regex
import gleam/string
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import shared.{
  type GridLetter, type LetterStatus, type Model, type Msg, Closed, Correct,
  ErrorDelayFinished, GridLetter, Lost, Model, Open, Pending, Playing,
  UserSentGameInput, Won, Wrong, WrongPos, delay, guess_max, not_word_err,
  too_short_err,
}

pub fn update_grid(
  model: Model,
  msg: Msg,
) -> Result(#(Model, effect.Effect(Msg)), Nil) {
  case msg {
    UserSentGameInput(input) ->
      case model.game_state {
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
    _, g if g < guess_max ->
      Model(..model, guess: model.guess <> get_alpha(input))
    _, _ -> model
  }
}

fn handle_guess(model: Model) {
  case string.length(model.guess), list.contains(model.words, model.guess) {
    g, True if g == guess_max -> {
      let state = case
        model.guess
        == model.word,
        list.length(model.guesses)
        + 1
      {
        True, _ -> Won
        False, tries if tries == guess_max -> Lost
        _, _ -> Playing
      }
      let checked_guess =
        calculate_guess(model.guesses, model.guess, model.word)
      Model(
        ..model,
        guess: "",
        guesses: checked_guess |> fn(g) { [g] } |> list.append(model.guesses, _),
        game_state: state,
        used_letters: update_letters(checked_guess, model.used_letters),
        end_game_modal: case state {
          Playing -> Closed
          _ -> Open
        },
      )
    }
    g, False if g == guess_max -> Model(..model, error: not_word_err)
    g, _ if g < guess_max -> Model(..model, error: too_short_err)
    _, _ -> model
  }
}

fn calculate_guess(guesses: List(List(GridLetter)), guess: String, word: String) {
  let guess_letters = string.to_graphemes(guess)
  let word_letters = string.to_graphemes(word)

  list.map2(guess_letters, word_letters, fn(g, w) {
    case g, w, string.contains(word, g) {
      g, w, True if g == w -> GridLetter(letter: g, status: Correct)
      _, _, True -> GridLetter(letter: g, status: WrongPos)
      _, _, _ -> GridLetter(letter: g, status: Wrong)
    }
  })
}

fn update_letters(
  guess: List(GridLetter),
  used_letters: Dict(String, LetterStatus),
) {
  list.fold(guess, used_letters, fn(res, guess_letter) {
    case dict.get(res, guess_letter.letter) {
      Ok(status) ->
        case guess_letter.status, status {
          _, Correct -> res
          Wrong, WrongPos -> res
          _, _ -> dict.insert(res, guess_letter.letter, guess_letter.status)
        }
      Error(_) -> dict.insert(res, guess_letter.letter, guess_letter.status)
    }
  })
}

fn get_alpha(input: String) {
  let assert Ok(re) = regex.from_string("[a-z]")
  let letter = string.lowercase(input)
  case regex.check(re, letter) {
    True -> letter
    False -> ""
  }
}

pub fn word_grid(model: Model) -> element.Element(Msg) {
  let grid_letters: List(List(GridLetter)) =
    list.concat([
      model.guesses,
      case model.game_state {
        Playing -> [
          list.append(
            list.map(string.to_graphemes(model.guess), fn(l) {
              GridLetter(letter: l, status: Pending)
            }),
            list.repeat(
              GridLetter(letter: "", status: Pending),
              guess_max - string.length(model.guess),
            ),
          ),
        ]
        _ -> []
      },
      list.repeat(
        list.repeat(GridLetter(letter: "", status: Pending), guess_max),
        guess_max
          - case model.game_state {
          Playing -> list.length(model.guesses) + 1
          _ -> list.length(model.guesses)
        },
      ),
    ])

  html.div(
    [],
    list.map(grid_letters, fn(row: List(GridLetter)) {
      html.div(
        [attribute.class("grid_row")],
        list.map(row, fn(g_letter: GridLetter) {
          html.div(
            list.append([attribute.class("grid_letter_container")], case
              g_letter.status
            {
              Correct -> [attribute.class("correct")]
              WrongPos -> [attribute.class("wrong-pos")]
              Wrong -> [attribute.class("wrong")]
              _ -> []
            }),
            [element.text(string.uppercase(g_letter.letter))],
          )
        }),
      )
    })
      |> list.append([keyboard(model)]),
  )
}
