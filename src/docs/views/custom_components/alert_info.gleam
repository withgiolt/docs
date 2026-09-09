import lucide_lustre
import lustre/attribute
import lustre/element
import mork/document

pub fn container(content: String) {
  let icon =
    element.to_document_string(
      lucide_lustre.info([attribute.class("h-6 w-6 shrink-0 stroke-current")]),
    )

  document.HtmlBlock(
    "<div class=\"alert alert-info\">" <> icon <> "<div>" <> content <> "</div></div>",
  )
}
