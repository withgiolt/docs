import lustre/attribute
import lustre/element/html

pub fn element() {
  html.div([attribute.class("navbar w-full")], [
    html.label(
      [
        attribute.for("drawer"),
        attribute.aria_label("open sidebar"),
        attribute.class("btn btn-ghost drawer-button"),
      ],
      [html.text("Open")],
    ),
  ])
}
