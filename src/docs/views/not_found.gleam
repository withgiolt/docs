import docs/views/default_layout
import lustre/attribute
import lustre/element/html

pub fn element() {
  default_layout.element("/404", "Page not found", [
    html.div(
      [
        attribute.class(
          "container pt-24 flex flex-col items-center text-center gap-4",
        ),
      ],
      [
        html.h1([attribute.class("font-pixel text-5xl")], [
          html.text("404"),
        ]),
        html.p([attribute.class("text-base-content/70")], [
          html.text("This page doesn't exist."),
        ]),
        html.a([attribute.class("btn btn-primary"), attribute.href("/")], [
          html.text("Back home"),
        ]),
      ],
    ),
  ])
}
