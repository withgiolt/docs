import docs/views/navbar
import gleam/list
import lucide_lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type SidebarFeature {
  SidebarLink(text: String, link: String, new_tab: Bool, current_path: String)
  SidebarDropdown(text: String, sub: List(SidebarFeature))
  SidebarDivider
}

fn get_sidebar_features(current_path: String) {
  [
    SidebarLink("Giolt", "https://giolt.com", False, current_path:),
    SidebarDivider,
    SidebarLink("Home", "/", False, current_path:),
  ]
}

fn sidebar_feature(link: SidebarFeature) {
  case link {
    SidebarLink(text, link, external, current_path) -> {
      html.li([], [
        html.a(
          [
            attribute.href(link),
            attribute.classes([#("menu-active", current_path == link)]),
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
          html.details([attribute.open(True)], [
            html.summary([attribute.class("menu-dropdown-toggle")], [
              html.text(text),
            ]),
            html.ul(
              [attribute.class("menu-dropdown")],
              list.map(sub, sidebar_feature),
            ),
          ]),
        ]),
      ])
    }
    SidebarDivider -> {
      html.div([attribute.class("divider")], [])
    }
  }
}

pub fn element(
  current_path: String,
  title title: String,
  children children: List(Element(Nil)),
) {
  let title = case title {
    "Giolt Docs" -> "Giolt Docs — Hosting for Gleam"
    title -> title <> " — Giolt"
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
      html.title([], title),
    ]),
    html.body([attribute.class("flex flex-col min-svh")], [
      html.div([attribute.class("drawer lg:drawer-open")], [
        html.input([
          attribute.id("drawer"),
          attribute.type_("checkbox"),
          attribute.class("drawer-toggle"),
        ]),
        html.div([attribute.class("drawer-content")], [
          navbar.element(),
          html.main([attribute.class("flex-1")], children),
        ]),

        html.div([attribute.class("drawer-side")], [
          html.label(
            [
              attribute.for("drawer"),
              attribute.aria_label("close sidebar"),
              attribute.class("drawer-overlay"),
            ],
            [],
          ),
          html.ul(
            [attribute.class("menu bg-base-200 min-h-full w-80 p-4")],
            list.map(get_sidebar_features(current_path), sidebar_feature),
          ),
        ]),
      ]),
    ]),
  ])
}
