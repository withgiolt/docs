import docs/components/footer
import docs/components/head_tags
import docs/components/sidebar
import docs/views/navbar
import gleam/list
import lucide_lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// The frame around every page. `edit_path` is the page's file under
/// `src/content`, passed to the footer's edit link; leave it empty for a page
/// with no source file.
pub fn element(
  current_path current_path: String,
  title title: String,
  edit_path edit_path: String,
  children children: List(Element(Nil)),
) {
  let formatted_title = case title {
    "Giolt Docs" -> "Giolt Docs - Hosting for Gleam"
    title -> title <> " - Giolt Docs"
  }

  html.html([attribute.lang("en")], [
    html.head([], head_tags.element(title: formatted_title)),
    html.body([attribute.class("flex flex-col min-svh")], [
      html.a(
        [
          attribute.href("#main-content"),
          attribute.class(
            "sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-100 focus:px-3 btn btn-sm",
          ),
        ],
        [html.text("Skip to content")],
      ),
      html.div([attribute.class("drawer lg:drawer-open")], [
        html.input([
          attribute.id("drawer"),
          attribute.type_("checkbox"),
          attribute.class("drawer-toggle"),
        ]),
        html.div([attribute.class("drawer-content min-h-svh flex flex-col")], [
          navbar.element(title),
          html.main(
            [
              attribute.id("main-content"),
              attribute.class("flex-1 lg:ml-80 mt-16 lg:mt-0"),
            ],
            [
              html.div(
                [attribute.class("docs-column pt-8 lg:pt-12 pb-8")],
                list.append(children, [footer.element(edit_path:)]),
              ),
            ],
          ),
        ]),
        html.div(
          [
            attribute.id("drawer-side"),
            attribute.class("drawer-side fixed z-50"),
          ],
          [
            html.label(
              [
                attribute.for("drawer"),
                attribute.aria_label("close sidebar"),
                attribute.attribute("aria-controls", "drawer-side"),
                attribute.class("drawer-overlay"),
              ],
              [],
            ),
            html.div(
              [
                attribute.class(
                  "navbar bg-base-100 z-50 border-r border-base-200 px-4 w-80",
                ),
              ],
              [
                html.div([attribute.class("navbar-start")], [
                  html.a(
                    [
                      attribute.href("/"),
                      attribute.class("flex flex-row items-center gap-2"),
                    ],
                    [
                      html.img([
                        attribute.src("/logo_rounded.svg"),
                        attribute.alt(""),
                        attribute.class("size-8"),
                      ]),
                      html.span([attribute.class("font-pixel text-xl")], [
                        html.text("Giolt Docs"),
                      ]),
                    ],
                  ),
                ]),
                html.div([attribute.class("navbar-end")], [
                  html.label(
                    [
                      attribute.for("drawer"),
                      attribute.aria_label("close sidebar"),
                      attribute.attribute("aria-controls", "drawer-side"),
                      attribute.class(
                        "btn btn-square btn-ghost drawer-button lg:hidden",
                      ),
                    ],
                    [lucide_lustre.panel_left_close([])],
                  ),
                ]),
              ],
            ),
            sidebar.element(current_path:),
          ],
        ),
      ]),
    ]),
  ])
}
