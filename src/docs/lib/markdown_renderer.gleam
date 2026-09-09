import docs/views/custom_components/alert_info
import docs/views/custom_components/alert_warning
import docs/views/custom_components/codeblock
import gleam/list
import mork
import mork/document

pub fn parse(string: String) {
  let doc = mork.parse(string)

  let blocks = list.map(doc.blocks, render_block(doc, _))

  document.Document(..doc, blocks:)
  |> mork.to_html
}

fn render_block(doc: document.Document, block: document.Block) {
  case block {
    document.Code(lang, content) -> codeblock.container(lang, content)
    document.BlockQuote([document.Paragraph(_, inlines), ..rest]) ->
      case take_alert_marker(inlines) {
        Ok(#("warning", body)) ->
          render_alert(doc, alert_warning.container, body, rest)
        Ok(#("info", body)) ->
          render_alert(doc, alert_info.container, body, rest)
        _ -> block
      }
    _ -> block
  }
}

fn render_alert(
  doc: document.Document,
  wrap: fn(String) -> document.Block,
  body: List(document.Inline),
  rest: List(document.Block),
) {
  let content_blocks = case body {
    [] -> rest
    _ -> [document.Paragraph("", body), ..rest]
  }

  document.Document(..doc, blocks: content_blocks)
  |> mork.to_html
  |> wrap
}

fn take_alert_marker(inlines: List(document.Inline)) {
  case leading_text_line(inlines, "") {
    Ok(#("[!WARNING]", rest)) -> Ok(#("warning", rest))
    Ok(#("[!INFO]", rest)) -> Ok(#("info", rest))
    _ -> Error(Nil)
  }
}

fn leading_text_line(inlines: List(document.Inline), acc: String) {
  case inlines {
    [document.Text(t), ..rest] -> leading_text_line(rest, acc <> t)
    [document.SoftBreak, ..rest] -> Ok(#(acc, rest))
    [document.HardBreak, ..rest] -> Ok(#(acc, rest))
    [] -> Ok(#(acc, []))
    _ -> Error(Nil)
  }
}
