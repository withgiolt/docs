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
  |> bundle.run
}
```

Run with `gleam run -m build`.

There is nothing to configure about the bundle itself — Giolt produces one shape of
artifact: a minified, tree-shaken ESM bundle wrapped in the platform's worker entry.
`bundle.run` reads your already-compiled JavaScript output; it does not run
`gleam build` for you, so compile your project first.

`bundle.entry` takes a **path to a JavaScript file**, not a Gleam module name. That
is usually your compiled Gleam entry module, but it can be any JavaScript file — including
one you have already run your own esbuild over, which Giolt then bundles again to adapt
it to the platform.

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

### How the dev loop restarts

`dev.run` supervises itself. The first process compiles your project, then spawns a
child that runs `prebuild`, your `build` closure, the watcher and the server. When a
watched file changes, the child exits, the parent recompiles, and a fresh child starts.

That restart is the point. A long-lived process holds its imported modules in memory,
so a `build` closure that generates output **in-process** — a static site generator,
codegen, templating — would otherwise keep rendering from the code that was loaded when
the process started, even after your Gleam had been recompiled on disk. Steps that shell
out (esbuild, Tailwind) never had that problem, so the symptom was a confusing one:
generated pages stale while worker-rendered routes updated fine. Restarting means your
`build` closure always runs against freshly compiled code.

Because the supervisor compiles before every child, your `build` closure does not need
to compile the project itself. There is no `dev.compile` — it was removed in **3.0.0**.
If you are upgrading, drop the `use _ <- result.try(dev.compile())` line (and the
`gleam/result` import, if that was its only use).

> [!NOTE]
> Running the dev loop under Deno (`gleam run --runtime deno`) needs permissions for
> spawning subprocesses and reading and writing files. The simplest setup is
> `[javascript.deno]` with `allow_all = true` in your `gleam.toml`.

> [!WARNING]
> This page is still work in progress.
