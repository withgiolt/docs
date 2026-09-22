//// Local development server, run with `just dev` (`gleam dev`).
////
//// `dev.run` supervises itself: the parent process recompiles the project
//// and the child rebuilds, watches and serves. That restart is what makes
//// the `dev.build` closure below pick up newly compiled Gleam, so there is
//// nothing to compile here.

import build
import giolt_sdk/dev
import gleam/result

pub fn main() {
  dev.new()
  |> dev.watch("./src")
  |> dev.watch("./public")
  |> dev.build(fn(_change) { build.build_all() |> result.replace(Nil) })
  // The bundle copies the generated site to `./dist/static`, which is what
  // Giolt serves as assets — so pointing the dev server at the same place
  // is what keeps local routing honest.
  |> dev.static_dir("./dist/static")
  |> dev.worker("./dist/index.mjs")
  |> dev.serve(port: 3000)
  |> dev.live_reload(True)
  |> dev.run
}
