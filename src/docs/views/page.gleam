import docs/views/default_layout
import gleam/dict
import gleam/result
import lucide_lustre
import lustre/attribute
import lustre/element
import lustre/element/html
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
    html.div([attribute.class("container pt-8")], [
      element.unsafe_raw_html(
        "",
        "article",
        [
          attribute.class(
            "prose prose-neutral dark:prose-invert max-w-none "
            <> "prose-headings:font-pixel prose-h1:text-5xl "
            <> "prose-pre:bg-base-200 prose-pre:text-base-content prose-pre:border prose-pre:border-base-300",
          ),
        ],
        page.content,
      ),
      html.div([attribute.class("my-8")], [
        html.a(
          [
            attribute.class("flex flex-row items-center gap-2 link text-sm"),
            attribute.target("_blank"),
            attribute.href(
              "https://github.com/withgiolt/docs/edit/main/src/content"
              <> page.current_path
              <> ".dj",
            ),
          ],
          [
            lucide_lustre.pen([attribute.class("size-4")]),
            html.p([], [html.text("Edit page")]),
          ],
        ),
      ]),
    ]),
  ])
}
