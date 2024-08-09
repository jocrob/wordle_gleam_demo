import gleam/dynamic
import gleam/list
import gleam/io
import lustre/element
import lustre/attribute
import lustre/event
import lustre/element/html
import lustre/effect
import shared.{
    Playing,
    Open,
    Closed,
    Transition,
    UserChangedModalState,
    Model,
    type Msg,
    type Model
}

pub fn update_end_game_modal(model: Model, msg: Msg) -> Result(#(Model, effect.Effect(Msg)), Nil) {
    case msg {
        UserChangedModalState(state) -> case state {
            Closed -> Ok(#(Model(..model, end_game_modal: state, game_state: Playing), effect.none()))
            _ -> Ok(#(Model(..model, end_game_modal: state), effect.none()))
        }
        _ -> Error(Nil)
    }
}

fn handle_close_transition(_event) -> Result(Msg, List(dynamic.DecodeError)) {
    io.debug("handling close")
    Ok(UserChangedModalState(Closed))
}

pub fn end_game_modal(model: Model) -> element.Element(Msg) {
    io.debug(model.end_game_modal)

    case model.end_game_modal != Closed {
        True -> html.div(
                list.append([attribute.class("overlay")], case model.end_game_modal {
                    Open -> [attribute.class("ease-in")]
                    Transition -> [attribute.class("ease-out"), event.on("animationend", handle_close_transition)]
                    Closed -> []
                }), 
                [
                    html.div([attribute.class("end-game-container")], [element.text("Done")]),
                    html.button([event.on_click(UserChangedModalState(Transition))], [element.text("Close")])
                ]
            ) 
        False -> element.none()
    }
}