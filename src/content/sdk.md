---
title = "Giolt SDK"
---

# Giolt SDK

There is no CLI. `giolt_sdk` is a Gleam **library** — you write plain Gleam scripts that
call into it, and you own your own build. The only thing invoked by module name is a
one-shot scaffolder. The SDK targets `javascript` only; there is no Erlang support yet.

## Installation

Add the SDK as a dependency:

```sh
gleam add giolt_sdk
```

## Get started

```sh
gleam run -m giolt_sdk/init
```

This reads your project name out of `gleam.toml` and writes three files into `src/`,
skipping any that already exist:

- **`build.gleam`** — bundles your app for the Giolt platform.
- **`deploy.gleam`** — ships a bundle.
- **`{project}_dev.gleam`** — watches, rebuilds and serves your app locally.

Each of these calls into one of the SDK's three public modules — `giolt_sdk/bundle`,
`giolt_sdk/deploy` and `giolt_sdk/dev` — which together are the entire public API. Each
is an opaque builder: you configure it with a chain of setters and finish with `run`.
Required fields are enforced at compile time, so a builder that's missing something it
needs won't typecheck.

## `build.gleam`

```gleam
import giolt_sdk/bundle

pub fn main() {
  bundle.new()
  |> bundle.entry("./build/dev/javascript/app/app.mjs")
  |> bundle.static_dir("./public")
  |> bundle.outdir("./dist")
  |> bundle.additional_args(["--external:node:crypto"])
  |> bundle.run
}
```

Run with `gleam run -m build`.

Giolt produces one shape of artifact by default: a minified, tree-shaken ESM bundle
wrapped in the platform's worker entry. `bundle.run` reads your already-compiled
JavaScript output; it does not run `gleam build` for you, so compile your project first.

`bundle.entry` takes a **path to a JavaScript file**, not a Gleam module name. That
is usually your compiled Gleam entry module, but it can be any JavaScript file — including
one you have already run your own esbuild over, which Giolt then bundles again to adapt
it to the platform.

`bundle.additional_args` takes a raw list of esbuild flags, appended after the SDK's
own — later flags win, so it's how you override a default (`--minify=false`) or mark
something `--external` so esbuild doesn't bundle it a second time when you've already
run your own esbuild pass over the entry file.

Your entry module needs to export a single function:

```gleam
pub fn handler(request: Request(Body)) -> Response(Body) {
  // or: -> Promise(Response(Body))
}
```

## `deploy.gleam`

```gleam
import build
import giolt_sdk/deploy
import gleam/javascript/promise

pub fn main() {
  let assert Ok(output) = build.main()

  deploy.new()
  |> deploy.project_id("prj_replace_me")
  |> deploy.from(output)
  |> deploy.preview(True)
  |> deploy.token_from_env("GIOLT_TOKEN")
  |> deploy.run
  |> promise.map(deploy.print_result)
}
```

Run with `gleam run -m deploy`. `deploy.token_from_env` reads the named environment
variable for authentication - it's the only place the SDK touches your environment.

## `{project}_dev.gleam`

```gleam
import giolt_sdk/bundle
import giolt_sdk/dev

pub fn main() {
  dev.new()
  |> dev.watch("./src")
  |> dev.watch("./public")
  |> dev.prebuild(fn() { Ok(Nil) })
  |> dev.build(fn(_change) {
    bundle.new()
    |> bundle.entry("./build/dev/javascript/app/app.mjs")
    |> bundle.static_dir("./public")
    |> bundle.run
    |> bundle.discard_output
  })
  |> dev.serve(port: 3000)
  |> dev.worker("./dist/index.mjs")
  |> dev.static_dir("./public")
  |> dev.live_reload(True)
  |> dev.run
}
```

Run with `gleam dev`. `dev.watch` takes one or more directories to watch for changes.
The dev server serves `static_dir`, hot-reloads the built `worker`, and (when
`live_reload` is enabled) pushes browser reloads over SSE.

> [!WARNING]
> This page is still work in progress.
