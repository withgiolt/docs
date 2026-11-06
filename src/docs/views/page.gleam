import docs/components/session
import docs/components/toc
import docs/lib/markdown_renderer.{type Heading}
import docs/views/default_layout
import gleam/dict
import gleam/result
import lustre/attribute
import lustre/element
import lustre/element/html
import tom

pub type Page {
  Page(
    frontmatter: dict.Dict(String, tom.Toml),
    content: String,
    headings: List(Heading),
    current_path: String,
  )
}

pub fn element(page: Page) {
  let title =
    tom.get_string(page.frontmatter, ["title"]) |> result.unwrap("Giolt Docs")

  // The home page is src/content/index.md but is served at "/".
  let edit_path = case page.current_path {
    "/" -> "/index"
    path -> path
  }

  default_layout.element(
    current_path: page.current_path,
    title:,
    edit_path:,
    children: [
      html.div(
        [
          attribute.class(
            "grid grid-cols-1 xl:grid-cols-[minmax(0,1fr)_14rem] gap-x-10 gap-y-6",
          ),
        ],
        [
          session.body([attribute.class("flex flex-col gap-6")], [
            toc.collapsible(page.headings),
            element.unsafe_raw_html(
              "",
              "article",
              [
                attribute.class(
                  "prose prose-neutral dark:prose-invert max-w-none "
                  <> "prose-pre:border prose-pre:border-base-300",
                ),
              ],
              page.content,
            ),
          ]),
          toc.column(page.headings),
        ],
      ),
    ],
  )
}
