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
      "article",
      [
        attribute.class(
          "prose prose-neutral dark:prose-invert p-4 max-w-5xl mx-auto "
          <> "prose-headings:font-pixel prose-h1:text-5xl "
          <> "prose-pre:bg-base-200 prose-pre:text-base-content prose-pre:border prose-pre:border-base-300",
        ),
      ],
      page.content,
    ),
  ])
}
