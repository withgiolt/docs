import gleam/dict
import gleam/option
import jot
import lucide_lustre
import lustre/attribute
import lustre/element

pub fn container(items: List(jot.Container)) {
  jot.Div(option.None, dict.from_list([#("class", "alert alert-warning")]), [
    jot.RawBlock(
      element.to_document_string(
        lucide_lustre.triangle_alert([
          attribute.class("h-6 w-6 shrink-0 stroke-current"),
        ]),
      ),
    ),
    jot.Div(option.None, dict.new(), items),
  ])
}
