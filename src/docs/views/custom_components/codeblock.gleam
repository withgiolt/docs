import gleam/option
import jot
import lustre/element
import lustre/element/html
import smalto
import smalto/grammar
import smalto/languages/bash
import smalto/languages/gleam
import smalto/lustre as smalto_lustre
import smalto/lustre/themes

pub fn container(language: option.Option(String), content: String) {
  let lang = case language {
    option.Some(lang) -> {
      case lang {
        "bash" -> bash.grammar()
        "gleam" -> gleam.grammar()
        _ -> grammar.Grammar("none", option.None, [])
      }
    }
    option.None -> grammar.Grammar("none", option.None, [])
  }

  let tokens = smalto.to_tokens(content, lang)
  let elements = smalto_lustre.to_lustre(tokens, themes.one_dark())

  let html = element.to_document_string(html.pre([], elements))

  jot.RawBlock(html)
}
