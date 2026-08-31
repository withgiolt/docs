import docs/lib/sidebar_features.{
  type SidebarFeature, SidebarDivider, SidebarDropdown, SidebarLink,
}
import docs/views/navbar
import gleam/list
import lucide_lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

fn sidebar_feature(link: SidebarFeature) {
  case link {
    SidebarLink(text, link, external, current_path) -> {
      html.li([], [
        html.a(
          [
            attribute.href(link),
            attribute.classes([#("menu-focus", current_path == link)]),
            ..case external {
              True -> [attribute.target("_blank")]
              False -> []
            }
          ],
          [
            case external, link {
              True, _ | _, "http" <> _ ->
                lucide_lustre.external_link([attribute.class("size-4")])
              False, _ -> element.none()
            },
            html.text(text),
          ],
        ),
      ])
    }
    SidebarDropdown(text, sub) -> {
      element.fragment([
        html.li([], [
          html.p([attribute.class("menu-title")], [
            html.text(text),
          ]),
          html.ul([], list.map(sub, sidebar_feature)),
        ]),
      ])
    }
    SidebarDivider -> {
      html.div([attribute.class("divider")], [])
    }
  }
}

pub fn element(
  current_path current_path: String,
  title title: String,
  children children: List(Element(Nil)),
) {
  let formatted_title = case title {
    "Giolt Docs" -> "Giolt Docs — Hosting for Gleam"
    title -> title <> " — Giolt Docs"
  }

  html.html([attribute.lang("en")], [
    html.head([], [
      html.meta([attribute.charset("utf-8")]),
      html.link([
        attribute.href("/favicon.svg"),
        attribute.type_("image/svg+xml"),
        attribute.rel("icon"),
      ]),
      html.meta([
        attribute.content(
          "width=device-width, initial-scale=1, viewport-fit=cover",
        ),
        attribute.name("viewport"),
      ]),
      html.meta([
        attribute.name("description"),
        attribute.content(
          "Giolt is the hosting platform for Gleam. Static deploys for JavaScript target today, serverless BEAM soon. Join the waitlist.",
        ),
      ]),
      html.meta([
        attribute.name("apple-mobile-web-app-capable"),
        attribute.content("yes"),
      ]),
      html.meta([
        attribute.name("apple-mobile-web-app-status-bar-style"),
        attribute.content("black-translucent"),
      ]),
      html.link([
        attribute.rel("preconnect"),
        attribute.href("https://fonts.googleapis.com"),
      ]),
      html.link([
        attribute.rel("preconnect"),
        attribute.href("https://fonts.gstatic.com"),
        attribute.crossorigin(""),
      ]),
      html.link([
        attribute.href(
          "https://fonts.googleapis.com/css2?family=Geist+Mono:ital,wght@0,100..900;1,100..900&family=Geist+Pixel&display=swap",
        ),
        attribute.rel("stylesheet"),
      ]),
      html.link([attribute.rel("stylesheet"), attribute.href("/docs.css")]),
      html.script(
        [
          attribute.attribute("defer", ""),
          attribute.src(
            "https://api.dashboard.instatus.com/widget?host=withgiolt.instatus.com&code=ada685d9&locale=en",
          ),
        ],
        "",
      ),
      html.title([], formatted_title),
    ]),
    html.body([attribute.class("flex flex-col min-svh")], [
      html.div([attribute.class("drawer lg:drawer-open")], [
        html.input([
          attribute.id("drawer"),
          attribute.type_("checkbox"),
          attribute.class("drawer-toggle"),
        ]),
        html.div([attribute.class("drawer-content")], [
          navbar.element(title),
          html.main([attribute.class("flex-1 lg:ml-80 mt-16")], children),
        ]),

        html.div([attribute.class("drawer-side fixed z-50")], [
          html.label(
            [
              attribute.for("drawer"),
              attribute.aria_label("close sidebar"),
              attribute.class("drawer-overlay"),
            ],
            [],
          ),
          html.div(
            [
              attribute.class(
                "navbar bg-base-100 z-50 border-b border-r border-base-200 px-4 w-80",
              ),
            ],
            [
              html.div([attribute.class("navbar-start")], [
                html.h1(
                  [
                    attribute.class(
                      "flex flex-row items-center gap-2 font-bold",
                    ),
                  ],
                  [
                    html.img([
                      attribute.src("/logo_rounded.svg"),
                      attribute.class("size-8"),
                    ]),
                    html.text("Giolt Docs"),
                  ],
                ),
              ]),
              html.div([attribute.class("navbar-end")], [
                html.label(
                  [
                    attribute.for("drawer"),
                    attribute.aria_label("close sidebar"),
                    attribute.class(
                      "btn btn-square btn-ghost drawer-button lg:hidden",
                    ),
                  ],
                  [lucide_lustre.panel_left_close([])],
                ),
              ]),
            ],
          ),
          html.ul(
            [
              attribute.class(
                "menu bg-base-100 border-r border-base-200 min-h-full w-80 p-4 pt-20 lg:pt-4",
              ),
            ],
            list.map(
              sidebar_features.get_sidebar_features(current_path),
              sidebar_feature,
            ),
          ),
        ]),
      ]),
    ]),
  ])
}
