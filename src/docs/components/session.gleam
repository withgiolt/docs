import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// The text column. It leaves a left gutter for `sigil` to hang in, so heading
/// words line up with the copy below them.
pub fn body(
  attrs: List(attribute.Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  html.div([attribute.class("session-body"), ..attrs], children)
}

/// A page title set as a shell comment.
pub fn title(children: List(Element(msg))) -> Element(msg) {
  html.h1(
    [attribute.class("relative font-pixel text-4xl md:text-5xl text-balance")],
    [sigil(), ..children],
  )
}

/// Hidden from screen readers, so a heading is announced as its words alone.
pub fn sigil() -> Element(msg) {
  html.span([attribute.class("session-sigil"), attribute.aria_hidden(True)], [
    html.text("#"),
  ])
}
