import lucide_lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Closes every page. `edit_path` is the page's file under `src/content`, or
/// empty where there is no file to edit, as on the 404 page.
pub fn element(edit_path edit_path: String) -> Element(msg) {
  html.footer(
    [
      attribute.class(
        "mt-16 py-6 border-t border-base-content/20 flex flex-wrap items-center justify-between gap-x-6 gap-y-3 text-sm",
      ),
    ],
    [
      case edit_path {
        "" -> element.none()
        path ->
          html.a(
            [
              attribute.class("flex flex-row items-center gap-2 link"),
              attribute.target("_blank"),
              attribute.rel("noopener noreferrer"),
              attribute.href(
                "https://github.com/withgiolt/docs/edit/main/src/content"
                <> path
                <> ".md",
              ),
            ],
            [
              lucide_lustre.pen([attribute.class("size-4")]),
              html.text("Edit page"),
              html.span([attribute.class("sr-only")], [
                html.text(" (opens in new tab)"),
              ]),
            ],
          )
      },
      html.p([], [html.text("Giolt - Hosting for Gleam © 2026")]),
    ],
  )
}
