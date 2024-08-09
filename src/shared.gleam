import lustre_http
import lustre/effect
import gleam/io

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
    GridLetter(
        letter: String,
        status: LetterStatus
    )
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
        used_letters: List(String),
        error: String,
        game_state: GameState,
        end_game_modal: ModalState
    )
}

pub type Msg {
    ApiReturnedWords(Result(List(String), lustre_http.HttpError))
    UserSentGameInput(String)
    ErrorDelayFinished
    UserChangedModalState(ModalState)
}

pub fn delay(amount: Int, msg: Msg) -> effect.Effect(Msg) {
    effect.from(fn(dispatch) {
        do_delay(amount, fn() {
            dispatch(msg)
        })
    })
}

@external(javascript, "./app.ffi.mjs", "delay")
fn do_delay(amount: Int, cb: fn() -> Nil) -> Nil {
    Nil
}