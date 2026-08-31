import lustre/attribute.{type Attribute, attribute}
import lustre/element/svg

pub fn external_link(attributes: List(Attribute(a))) {
  svg.svg(
    [
      attribute("stroke-linejoin", "round"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-width", "2"),
      attribute("stroke", "currentColor"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      attribute("height", "24"),
      attribute("width", "24"),
      ..attributes
    ],
    [
      svg.path([attribute("d", "M15 3h6v6")]),
      svg.path([attribute("d", "M10 14 21 3")]),
      svg.path([
        attribute(
          "d",
          "M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6",
        ),
      ]),
    ],
  )
}
