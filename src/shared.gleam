import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/string
import lustre/effect
import lustre_http

pub const guess_max = 5

pub const not_word_err = "Not a word"

pub const too_short_err = "Too short"

pub type LetterStatus {
  Correct
  WrongPos
  Wrong
  Pending
}

pub type GameState {
  Won
  Playing
  Lost
}

pub type GridLetter {
  GridLetter(letter: String, status: LetterStatus)
}

pub type ModalState {
  Open
  Transition
  Closed
}

pub type Model {
  Model(
    words: List(String),
    word: String,
    guess: String,
    guesses: List(List(GridLetter)),
    used_letters: Dict(String, LetterStatus),
    error: String,
    game_state: GameState,
    end_game_modal: ModalState,
  )
}

pub type Msg {
  ApiReturnedWords(Result(List(String), lustre_http.HttpError))
  UserSentGameInput(String)
  ErrorDelayFinished
  UserChangedModalState(ModalState)
}

fn alphabet() -> Dict(String, LetterStatus) {
  list.range(97, 122)
  |> list.filter_map(string.utf_codepoint)
  |> string.from_utf_codepoints
  |> string.to_graphemes
  |> list.fold(dict.new(), fn(res, letter) { dict.insert(res, letter, Pending) })
}

pub fn init_model() {
  Model(
    words: [],
    word: "",
    guess: "",
    guesses: [],
    used_letters: alphabet(),
    error: "",
    game_state: Playing,
    end_game_modal: Closed,
  )
}

pub fn delay(amount: Int, msg: Msg) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) { do_delay(amount, fn() { dispatch(msg) }) })
}

@external(javascript, "./app.ffi.mjs", "delay")
fn do_delay(amount: Int, cb: fn() -> Nil) -> Nil {
  Nil
}

pub fn get_random_word(words: List(String)) {
  case
    {
      words
      |> iterator.from_list
      |> iterator.at(int.random(list.length(words)))
    }
  {
    Ok(word) -> word
    Error(_) -> ""
  }
}
