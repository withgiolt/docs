---
title = "Giolt SDK"
---

# Giolt SDK

There is no CLI. `giolt_sdk` is a Gleam **library** — you write plain Gleam scripts that
call into it, and you own your own build. The only thing invoked by module name is a
one-shot scaffolder. The SDK targets `javascript` only; there is no Erlang support yet.

## Installation

```sh
gleam add giolt_sdk
```

## Scaffolding

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
Required fields are enforced at compile time — a builder missing something it needs
won't typecheck, so `bundle.new() |> bundle.run` is a compile error, not a runtime one.

For a walkthrough of all three from a fresh project, see [Get started](/get-started).

## `giolt_sdk/bundle`

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

Run with `gleam run -m build`. `bundle.run` only reads whatever `bundle.entry` points
at — it does not run `gleam build` for you, so compile your project first
(`gleam build --target javascript`).

There is nothing else to configure about the bundle's shape — Giolt produces one kind
of artifact: a minified, tree-shaken ESM bundle wrapped in the platform's worker entry.

- **`bundle.entry(path)`** — required. Path to a JavaScript file — usually your
  compiled Gleam module, but it can be any file, including one your own build already
  produced.
- **`bundle.static_dir(path)`** — optional. A directory copied into the output as
  static assets.
- **`bundle.outdir(path)`** — optional, defaults to `./dist`. Refuses unsafe values
  (`.`, `/`, `..`) since it's deleted before every bundle.
- **`bundle.additional_args(args)`** — optional. Raw `List(String)` of esbuild flags
  appended after the SDK's own — later flags win, so it's how you override a default
  (`--minify=false`) or mark something `--external` so esbuild doesn't bundle it a
  second time.

Your entry module needs to export a single function:

```gleam
pub fn handler(request: Request(Body)) -> Response(Body) {
  // or: -> Promise(Response(Body))
}
```

That contract is checked at request time inside the generated worker shim, not by
scanning the entry file, so it works no matter how the export got there — including
through your own esbuild pass.

## `giolt_sdk/dev`

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

Run with `gleam run -m {project}_dev`.

- **`dev.watch(path)`** — required, at least one. A directory to watch for changes.
  Call it more than once to watch several.
- **`dev.build(fn(Change) -> Result(Nil, String))`** — required. Runs on startup and
  after every watched change.
- **`dev.prebuild(fn() -> Result(Nil, String))`** — optional. Runs once, before the
  first build.
- **`dev.serve(port:)`** — optional. Starts the dev HTTP server on this port.
- **`dev.worker(path)`** — optional, defaults to `./dist/index.mjs`. Path to the built
  worker module the server hot-reloads.
- **`dev.static_dir(path)`** — optional. A directory the dev server serves as static
  files.
- **`dev.live_reload(enabled)`** — optional, defaults to `True`. Pushes browser
  reloads over SSE on rebuild.

`dev.run` supervises itself: the first process runs `gleam build --target javascript`,
then spawns a child that runs your `build` closure, watches, and serves. On a watched
change the child exits and the parent recompiles before starting a fresh child. That
restart is what makes your `build` closure see newly compiled code — a long-lived
process holds its imported modules in memory, so anything that generates output
in-process would otherwise keep rendering from whatever was loaded at startup, even
after `gleam build` wrote fresh JS to disk. Because the supervisor compiles before
every child, your `build` closure never needs to compile the project itself — there is
no `dev.compile`.

## `giolt_sdk/deploy`

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

Run with `gleam run -m deploy`.

- **`deploy.project_id(id)`** — required. Your Giolt project id.
- **`deploy.from(output)`** / **`deploy.artifact(path)`** — exactly one required.
  `deploy.from` deploys the `bundle.Output` from a `bundle.run` call directly;
  `deploy.artifact` deploys an already-built directory instead.
- **`deploy.preview(bool)`** — optional, defaults to `False`. Deploy as a preview
  instead of production.
- **`deploy.token_from_env(var)`** — optional, defaults to `"GIOLT_TOKEN"`. Read the
  deploy token from the named environment variable.
- **`deploy.token(value)`** — optional. Pass the deploy token directly instead of
  reading it from the environment.
- **`deploy.message(text)`** — optional. A message to attach to the deployment.
- **`deploy.api_url(url)`** — optional, defaults to `https://giolt.com`. Also
  overridable via the `GIOLT_API_URL` environment variable, which takes precedence.

<<<<<<< HEAD

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
> \=======
> `deploy.token_from_env` (or the environment variable it names) is the one place the SDK
> reads your environment — there's no `.env` loading or general env-var handling
> elsewhere in the SDK.

## Next steps

- [Get started](/get-started) for a full walkthrough from a new project.
- [Report an issue](https://github.com/withgiolt/issues) if something's broken or
  missing.

> > > > > > > 0c23f01 (Updated documentation)
