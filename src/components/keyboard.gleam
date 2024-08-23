import gleam/dict
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import shared.{
  type Model, type Msg, Correct, Model, UserSentGameInput, Wrong, WrongPos,
}

const keys = ["QWERTYUIOP", "ASDFGHJKL", "oZXCVBNMx"]

pub fn keyboard(model: Model) -> element.Element(Msg) {
  html.div(
    [attribute.class("keyboard")],
    list.map(keys, fn(row) {
      html.div(
        [attribute.class("keyboard-row")],
        list.map(string.split(row, ""), fn(letter) {
          case letter {
            "o" ->
              html.button(
                [
                  attribute.class("key"),
                  attribute.class("func-key"),
                  attribute.class("default-color"),
                  event.on_click(UserSentGameInput("Enter")),
                ],
                [element.text("ENTER")],
              )
            "x" ->
              html.button(
                [
                  attribute.class("key"),
                  attribute.class("func-key"),
                  attribute.class("default-color"),
                  event.on_click(UserSentGameInput("Backspace")),
                ],
                [
                  html.span(
                    [
                      attribute.class("material-symbols-outlined"),
                      attribute.style([#("font-size", "2rem")]),
                    ],
                    [element.text("backspace")],
                  ),
                ],
              )
            _ ->
              html.button(
                case dict.get(model.used_letters, string.lowercase(letter)) {
                  Ok(status) ->
                    case status {
                      Correct -> [attribute.class("correct")]
                      WrongPos -> [attribute.class("wrong-pos")]
                      Wrong -> [attribute.class("wrong")]
                      _ -> [attribute.class("default-color")]
                    }
                  Error(_) -> [attribute.class("default-color")]
                }
                  |> list.append([
                    attribute.class("key"),
                    event.on_click(UserSentGameInput(letter)),
                  ]),
                [element.text(letter)],
              )
          }
        }),
      )
    }),
  )
}
