import lucide_lustre
import lustre/attribute
import lustre/element/html

pub fn element(title: String) {
  html.div(
    [
      attribute.class(
        "navbar fixed lg:left-80 z-40 border-b border-base-200 w-full bg-base-100",
      ),
    ],
    [
      html.label(
        [
          attribute.for("drawer"),
          attribute.aria_label("open sidebar"),
          attribute.class("btn btn-square btn-ghost drawer-button lg:hidden"),
        ],
        [lucide_lustre.panel_left_open([])],
      ),
      html.p(
        [attribute.class("ml-2 font-bold text-xl lg:hidden line-clamp-1")],
        [
          html.text(title),
        ],
      ),
    ],
  )
}
