import lustre/attribute
import lustre/element/html

pub fn element(title title: String) {
  [
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
        "Giolt is the hosting platform for Gleam. Serverless hosting for the JavaScript target today, serverless BEAM soon. Join the waitlist.",
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
    html.meta([
      attribute.name("theme-color"),
      attribute.content("oklch(92% 0 0)"),
      attribute.attribute("media", "(prefers-color-scheme: light)"),
    ]),
    html.meta([
      attribute.name("theme-color"),
      attribute.content("oklch(21% 0.006 56.043)"),
      attribute.attribute("media", "(prefers-color-scheme: dark)"),
    ]),
    preload_font("/fonts/geist-pixel-5.3.1-merged.woff2"),
    preload_font("/fonts/geist-mono-5.3.0.woff2"),
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
  ]
}

// Without this a first visit finds the fonts only after docs.css has downloaded
// and parsed. Font requests are always CORS, so a preload without
// `crossorigin` is fetched twice.
fn preload_font(href: String) {
  html.link([
    attribute.rel("preload"),
    attribute.href(href),
    attribute.attribute("as", "font"),
    attribute.type_("font/woff2"),
    attribute.crossorigin("anonymous"),
  ])
}
