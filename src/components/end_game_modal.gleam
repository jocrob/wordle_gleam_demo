import gleam/dynamic
import gleam/int
import gleam/list
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import shared.{
  type Model, type Msg, Closed, Model, Open, Transition, UserChangedModalState,
  Won, get_random_word, init_model,
}

pub fn update_end_game_modal(
  model: Model,
  msg: Msg,
) -> Result(#(Model, effect.Effect(Msg)), Nil) {
  case msg {
    UserChangedModalState(state) ->
      case state {
        Closed ->
          Ok(#(
            Model(
              ..init_model(),
              words: model.words,
              word: get_random_word(model.words),
            ),
            effect.none(),
          ))
        _ -> Ok(#(Model(..model, end_game_modal: state), effect.none()))
      }
    _ -> Error(Nil)
  }
}

fn handle_close(_event) -> Result(Msg, List(dynamic.DecodeError)) {
  Ok(UserChangedModalState(Closed))
}

pub fn end_game_modal(model: Model) -> element.Element(Msg) {
  case model.end_game_modal != Closed {
    True ->
      html.div(
        list.append([attribute.class("overlay")], case model.end_game_modal {
          Open -> [attribute.class("ease-in")]
          Transition -> [
            attribute.class("ease-out"),
            event.on("animationend", handle_close),
          ]
          Closed -> []
        }),
        [
          html.div([attribute.class("end-game-container")], [
            case model.game_state {
              Won ->
                element.fragment([
                  html.h1([], [element.text("Congratulations!")]),
                  html.span([], [
                    element.text(
                      "You guessed the word in "
                      <> int.to_string(list.length(model.guesses))
                      <> case list.length(model.guesses) {
                        1 -> " try"
                        _ -> " tries"
                      },
                    ),
                  ]),
                ])
              _ ->
                element.fragment([
                  html.h1([], [element.text("Game Over")]),
                  html.span([], [
                    element.text("The word was \"" <> model.word <> "\""),
                  ]),
                ])
            },
            html.span([attribute.class("retry")], [element.text("Replay")]),
            html.button(
              [
                attribute.class("retry-button"),
                event.on_click(UserChangedModalState(Transition)),
              ],
              [
                html.span(
                  [
                    attribute.class("material-symbols-outlined"),
                    attribute.style([#("font-size", "60px")]),
                  ],
                  [element.text("replay")],
                ),
              ],
            ),
          ]),
        ],
      )
    False -> element.none()
  }
}
