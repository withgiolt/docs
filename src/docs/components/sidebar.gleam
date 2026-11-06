import docs/lib/sidebar_features.{
  type SidebarFeature, SidebarDivider, SidebarDropdown, SidebarLink,
}
import gleam/list
import lucide_lustre
import lustre/attribute
import lustre/element
import lustre/element/html

pub fn element(current_path current_path: String) {
  html.ul(
    [
      attribute.aria_label("Sidebar"),
      attribute.class(
        "menu bg-base-100 border-r border-base-200 min-h-full w-80 p-4 pt-20 lg:pt-4 lg:min-h-[calc(100%-5rem)]",
      ),
    ],
    list.map(
      sidebar_features.get_sidebar_features(current_path),
      sidebar_feature,
    ),
  )
}

fn sidebar_feature(feature: SidebarFeature) {
  case feature {
    SidebarLink(text, link, external, current_path) ->
      html.li([], [
        html.a(
          [
            attribute.href(link),
            attribute.classes([#("menu-focus", current_path == link)]),
            ..list.flatten([
              case current_path == link {
                True -> [attribute.attribute("aria-current", "page")]
                False -> []
              },
              case external {
                True -> [
                  attribute.target("_blank"),
                  attribute.rel("noopener noreferrer"),
                ]
                False -> []
              },
            ])
          ],
          [
            case external, link {
              True, _ | _, "http" <> _ ->
                lucide_lustre.external_link([attribute.class("size-4")])
              False, _ -> element.none()
            },
            html.text(text),
            case external {
              True ->
                html.span([attribute.class("sr-only")], [
                  html.text(" (opens in new tab)"),
                ])
              False -> element.none()
            },
          ],
        ),
      ])
    SidebarDropdown(text, sub) ->
      element.fragment([
        html.li([], [
          html.p([attribute.class("menu-title")], [html.text(text)]),
          html.ul([], list.map(sub, sidebar_feature)),
        ]),
      ])
    SidebarDivider -> html.div([attribute.class("divider")], [])
  }
}
