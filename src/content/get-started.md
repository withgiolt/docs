---
title = "Get started"
---

# Get started

This walks through taking a Gleam project from nothing to deployed on Giolt: install the
SDK, scaffold your build/dev/deploy scripts, write a handler, run it locally, and ship
it.

## Prerequisites

- [Gleam](https://gleam.run) installed.
- A Gleam project targeting `javascript` (Giolt has no Erlang support yet). If you don't
  have one, create one with:

  ```sh
  gleam new my_app
  cd my_app
  ```

## 1. Add the SDK

```sh
gleam add giolt_sdk
```

`giolt_sdk` is a library, not a CLI — it has no commands of its own beyond a one-shot
scaffolder. You write plain Gleam scripts that call into it, and you own your own build.

## 2. Scaffold your scripts

```sh
gleam run -m giolt_sdk/init
```

This reads your project name out of `gleam.toml` and writes three files into `src/`,
skipping any that already exist:

- **`build.gleam`** — bundles your app for the Giolt platform.
- **`deploy.gleam`** — ships a bundle to Giolt.
- **`{project}_dev.gleam`** — watches, rebuilds and serves your app locally.

Each is a short script that chains a builder from one of the SDK's three public
modules — `giolt_sdk/bundle`, `giolt_sdk/deploy`, `giolt_sdk/dev` — and finishes with
`run`. You're free to edit any of them afterwards; nothing about them is generated
again or overwritten.

## 3. Write a handler

Giolt expects your compiled entry module to export a single `handler` function:

```gleam
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}

pub fn handler(request: Request(String)) -> Response(String) {
  response.new(200)
  |> response.set_body("Hello from Giolt!")
}
```

`handler` can also return a `Promise(Response(Body))` if you need to do async work
(a database call, an outbound fetch) before responding.

## 4. Build it

Compile your project for the JavaScript target, then run the scaffolded build script:

```sh
gleam build --target javascript
gleam run -m build
```

`build.gleam` looks like this out of the box:

```gleam
import giolt_sdk/bundle

pub fn main() {
  bundle.new()
  |> bundle.entry("./build/dev/javascript/my_app/my_app.mjs")
  |> bundle.static_dir("./public")
  |> bundle.outdir("./dist")
  |> bundle.run
}
```

`bundle.entry` points at your compiled Gleam output by default, but it's just a path —
point it at any JavaScript file that exports `handler`, including one your own esbuild
pass already produced. `bundle.run` reads whatever that path points at; it does not
compile your project for you, which is why the `gleam build` step above comes first.

This produces a `./dist` folder: a minified, tree-shaken ESM bundle wrapped in the
platform's worker entry, plus anything from `./public` copied in as static assets.

## 5. Run it locally

```sh
gleam dev
```

(substitute your own project's name for `my_app`). The scaffolded dev script watches
`./src` and `./public`, rebuilds on change, and serves the result on `localhost:3000`
with live reload:

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
    |> bundle.entry("./build/dev/javascript/my_app/my_app.mjs")
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

`dev.run` recompiles your whole project before every rebuild, so edits to any Gleam
file — not just the ones under `dev.watch` — show up on the next reload once you save
a watched file.

## 6. Deploy it

Grab a deploy token from the [Giolt dashboard](https://giolt.com) — it already
resolves to exactly one project, so there's no project id to set — then export it:

```sh
export GIOLT_TOKEN=your_token_here
```

Run the scaffolded `deploy.gleam`:

```gleam
import build
import giolt_sdk/deploy
import gleam/javascript/promise

pub fn main() {
  let assert Ok(output) = build.main()

  deploy.new()
  |> deploy.from(output)
  |> deploy.preview(False)
  |> deploy.token_from_env("GIOLT_TOKEN")
  |> deploy.run
  |> promise.map(deploy.print_result)
}
```

```sh
gleam run -m deploy
```

`deploy.from(output)` chains directly off the `bundle.Output` your build produced, so
this always ships exactly what you just built. Set `deploy.preview(True)` while you're
testing a change to deploy without touching production.

## Next steps

- [Giolt SDK reference](/sdk) — every builder, every setter, and what each one
  defaults to.
- [Report an issue](https://github.com/withgiolt/issues) if something's broken,
  confusing, or missing.
