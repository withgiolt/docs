import docs/views/custom_components/alert_info
import docs/views/custom_components/alert_warning
import docs/views/custom_components/codeblock
import gleam/list
import gleam/option
import jot

pub fn parse(string: String) {
  let doc = jot.parse(string)

  let content =
    list.map(doc.content, fn(container) {
      case container {
        jot.Div(option.Some("warning"), _, items) ->
          alert_warning.container(items)
        jot.Div(option.Some("info"), _, items) -> alert_info.container(items)
        jot.Codeblock(_, lang, content) -> codeblock.container(lang, content)
        _ -> container
      }
    })

  jot.Document(..doc, content:)
  |> jot.document_to_html
}
