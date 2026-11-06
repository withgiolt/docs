import lucide_lustre
import lustre/attribute
import lustre/element/html

/// The bar for small screens, where the sidebar is a drawer. From `lg` the
/// sidebar is always open and carries the site name, so the bar is hidden.
pub fn element(title: String) {
  html.div(
    [
      attribute.class(
        "navbar fixed z-40 border-b border-base-200 w-full bg-base-100 lg:hidden",
      ),
    ],
    [
      html.label(
        [
          attribute.for("drawer"),
          attribute.aria_label("open sidebar"),
          attribute.attribute("aria-controls", "drawer-side"),
          attribute.class("btn btn-square btn-ghost drawer-button"),
        ],
        [lucide_lustre.panel_left_open([])],
      ),
      html.p([attribute.class("ml-2 font-bold text-xl line-clamp-1")], [
        html.text(title),
      ]),
    ],
  )
}
