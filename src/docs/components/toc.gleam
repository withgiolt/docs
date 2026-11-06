import docs/lib/markdown_renderer.{type Heading}
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// The page's headings as links. It needs no script: wide screens get a
/// sticky column beside the copy, and narrow ones a closed `details` above it.
/// A page with a single heading has nothing to navigate, so it gets neither.
pub fn column(headings: List(Heading)) -> Element(msg) {
  case list.length(headings) < 2 {
    True -> element.none()
    False ->
      html.aside(
        [
          attribute.class(
            "hidden xl:block sticky top-12 self-start max-h-[calc(100svh-6rem)] overflow-y-auto text-sm",
          ),
        ],
        [nav(headings)],
      )
  }
}

pub fn collapsible(headings: List(Heading)) -> Element(msg) {
  case list.length(headings) < 2 {
    True -> element.none()
    False ->
      html.details(
        [attribute.class("xl:hidden border border-base-content/20")],
        [
          html.summary([attribute.class("cursor-pointer px-4 py-3 font-bold")], [
            html.text("On this page"),
          ]),
          html.div([attribute.class("px-4 pb-3 text-sm")], [nav(headings)]),
        ],
      )
  }
}

fn nav(headings: List(Heading)) -> Element(msg) {
  html.nav([attribute.aria_label("On this page")], [
    html.p([attribute.class("hidden xl:block font-bold pb-2")], [
      html.text("On this page"),
    ]),
    html.ul([], list.map(headings, entry)),
  ])
}

fn entry(heading: Heading) -> Element(msg) {
  html.li([], [
    html.a(
      [
        attribute.href("#" <> heading.id),
        attribute.class("toc-link"),
        attribute.attribute("data-level", int.to_string(heading.level)),
      ],
      [html.text(heading.label)],
    ),
  ])
}
