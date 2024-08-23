import components/end_game_modal.{end_game_modal, update_end_game_modal}
import components/word_grid.{update_grid, word_grid}
import gleam/dynamic
import gleam/list
import gleam/result
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre_http
import shared.{
  type Model, type Msg, ApiReturnedWords, ErrorDelayFinished, Model,
  UserSentGameInput, get_host, get_random_word, init_model,
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(init_model(), get_words())
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  list.find_map(
    [update_api, update_grid, update_end_game_modal],
    fn(update_func) { update_func(model, msg) },
  )
  |> result.unwrap(#(model, effect.none()))
}

fn update_api(
  model: Model,
  msg: Msg,
) -> Result(#(Model, effect.Effect(Msg)), Nil) {
  case msg {
    ApiReturnedWords(Ok(response)) ->
      Ok(#(
        Model(..model, words: response, word: get_random_word(response)),
        effect.none(),
      ))
    ApiReturnedWords(Error(_)) -> Ok(#(model, effect.none()))
    ErrorDelayFinished -> Ok(#(Model(..model, error: ""), effect.none()))
    _ -> Error(Nil)
  }
}

fn get_words() -> effect.Effect(Msg) {
  let decoder = dynamic.list(of: dynamic.string)
  let expect = lustre_http.expect_json(decoder, ApiReturnedWords)

  let words_path = get_host() <> "priv/static/words.json"

  lustre_http.get(words_path, expect)
}

fn notification(error: String) -> element.Element(Msg) {
  case error != "" {
    True -> {
      html.div([attribute.class("overlay")], [
        html.div([attribute.class("notification-container")], [
          element.text(error),
        ]),
      ])
    }
    False -> element.none()
  }
}

fn view(model: Model) -> element.Element(Msg) {
  html.div(
    [
      attribute.class("container"),
      attribute.attribute("tabindex", "0"),
      event.on_keydown(UserSentGameInput),
    ],
    [word_grid(model), end_game_modal(model), notification(model.error)],
  )
}
