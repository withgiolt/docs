//// The Giolt worker behind docs.giolt.com.
////
//// Every page of this site is a static file produced by `build.gleam`, and
//// Giolt serves assets before a request ever reaches the worker. What lands
//// here is whatever matched no file, so this handler is the site's 404 page
//// and nothing else.

import conversation.{type RequestBody, type ResponseBody, Text}
import docs/views/not_found
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import lustre/element

pub fn handler(_req: Request(RequestBody)) -> Response(ResponseBody) {
  response.new(404)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(Text(element.to_document_string(not_found.element())))
}
