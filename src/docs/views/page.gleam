import docs/views/default_layout
import gleam/dict
import gleam/result
import lustre/attribute
import lustre/element
import tom

pub type Page {
  Page(
    frontmatter: dict.Dict(String, tom.Toml),
    content: String,
    current_path: String,
  )
}

pub fn element(page: Page) {
  let title =
    tom.get_string(page.frontmatter, ["title"]) |> result.unwrap("Giolt Docs")

  default_layout.element(page.current_path, title, [
    element.unsafe_raw_html(
      "",
      "div",
      [attribute.class("prose p-4")],
      page.content,
    ),
  ])
}
