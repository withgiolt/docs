import docs/components/session
import docs/views/default_layout
import lustre/attribute
import lustre/element/html

pub fn element() {
  default_layout.element(
    current_path: "/404",
    title: "Page not found",
    edit_path: "",
    children: [
      session.body([attribute.class("flex flex-col items-start gap-6")], [
        session.title([html.text("404")]),
        html.p([attribute.class("text-lg")], [
          html.text("This page doesn't exist."),
        ]),
        html.a([attribute.class("btn btn-primary"), attribute.href("/")], [
          html.text("Back home"),
        ]),
      ]),
    ],
  )
}
