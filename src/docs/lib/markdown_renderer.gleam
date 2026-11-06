import docs/views/custom_components/alert_info
import docs/views/custom_components/alert_warning
import docs/views/custom_components/codeblock
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/string
import mork
import mork/document

pub type Heading {
  Heading(level: Int, id: String, label: String)
}

pub type Rendered {
  Rendered(html: String, headings: List(Heading))
}

/// Renders the page and lists its `##` and `###` headings for the table of
/// contents. mork only sets a heading's id when the author writes `{#id}`, so
/// every heading gets a GitHub-style slug here, with `-1`, `-2` appended to
/// repeats, and links like `#static-sites` land on it.
pub fn parse(string: String) -> Rendered {
  let doc =
    mork.configure()
    |> mork.tables(True)
    |> mork.parse_with_options(string)

  let #(blocks, headings, _) =
    list.fold(doc.blocks, #([], [], dict.new()), fn(state, block) {
      let #(blocks, headings, seen) = state
      let #(block, heading, seen) = identify_heading(block, seen)
      let blocks = [render_block(doc, block), ..blocks]
      case heading {
        Ok(heading) -> #(blocks, [heading, ..headings], seen)
        Error(Nil) -> #(blocks, headings, seen)
      }
    })

  Rendered(
    html: document.Document(..doc, blocks: list.reverse(blocks))
      |> mork.to_html,
    headings: list.reverse(headings),
  )
}

fn identify_heading(block: document.Block, seen: Dict(String, Int)) {
  case block {
    document.Heading(level, _, raw, inlines) -> {
      let label = inline_text(inlines)
      let #(id, seen) = unique_slug(slug(label), seen)
      let heading = case level {
        2 | 3 -> Ok(Heading(level:, id:, label:))
        _ -> Error(Nil)
      }
      #(document.Heading(level, id, raw, inlines), heading, seen)
    }
    _ -> #(block, Error(Nil), seen)
  }
}

fn inline_text(inlines: List(document.Inline)) -> String {
  list.map(inlines, fn(inline) {
    case inline {
      document.Text(text) | document.CodeSpan(text) -> text
      document.Emphasis(children)
      | document.Strong(children)
      | document.Strikethrough(children)
      | document.Highlight(children) -> inline_text(children)
      document.FullLink(children, _) | document.RefLink(children, _) ->
        inline_text(children)
      document.SoftBreak | document.HardBreak -> " "
      _ -> ""
    }
  })
  |> string.concat
  |> string.trim
}

/// The slug GitHub gives a heading, so an anchor copied from a GitHub preview
/// works here too: lowercase, each space a hyphen, ASCII letters, digits, `_` and
/// `-` kept, and every other character dropped.
fn slug(label: String) -> String {
  label
  |> string.lowercase
  |> string.to_graphemes
  |> list.map(fn(grapheme) {
    case grapheme {
      " " -> "-"
      "_" | "-" -> grapheme
      _ ->
        case is_letter_or_digit(grapheme) {
          True -> grapheme
          False -> ""
        }
    }
  })
  |> string.concat
}

fn is_letter_or_digit(grapheme: String) -> Bool {
  case grapheme {
    "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" ->
      True
    "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" ->
      True
    "y" | "z" | "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ->
      True
    _ -> False
  }
}

fn unique_slug(base: String, seen: Dict(String, Int)) {
  case dict.get(seen, base) {
    Error(Nil) -> #(base, dict.insert(seen, base, 1))
    Ok(count) -> #(
      base <> "-" <> int.to_string(count),
      dict.insert(seen, base, count + 1),
    )
  }
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
