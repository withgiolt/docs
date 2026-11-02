---
title = "CLI"
---

# CLI

`giolt` is a Gleam package you run with `gleam run -m giolt <command>`. It builds,
runs and deploys your app, and it reads its configuration from `[tools.giolt]` in your
own `gleam.toml`, so there are no scripts to keep in sync. Bun is the supported
runtime; add `--runtime bun` to the command.

## Installation

```sh
gleam add --dev giolt
```

For a walkthrough from a fresh project, see [Get started](/get-started).

## Commands

| Command | What it does |
| --- | --- |
| `giolt build` | Checks `handle`, compiles and bundles into `outdir`. |
| `giolt dev` | Builds, watches, serves on `port` and reloads on change. JavaScript target only. |
| `giolt deploy [--preview] [--message TEXT]` | Builds, then uploads `outdir` to Giolt. JavaScript target only. |
| `giolt --help` | Prints the commands. `giolt <command> --help` prints that command's flags. |

A command that fails exits non-zero, so it works in CI and in scripts.

## The `handle` export

Your entry module exports one function named `handle`. On the JavaScript target:

```gleam
pub fn handle(
  request: Request(conversation.RequestBody),
) -> Response(conversation.ResponseBody) {
  // or: -> Promise(Response(conversation.ResponseBody))
}
```

On the Erlang target ([GlowVM](/glowvm/how-to-use)):

```gleam
pub fn handle(request: wisp.Request) -> wisp.Response
```

`giolt build` reads the types from `gleam export package-interface` and fails with a
clear message when `handle` is missing, still named `handler`, takes the wrong number of
parameters or has the wrong types. The generated worker also checks at request time, so
a bundle you produced another way still gets a clear 500 instead of a crash.

Deployed Workers carry no bindings — no env vars, no KV/D1/R2, no secrets. See
[Limits](/limits) for this and everything else not supported yet.

## Configuration

Every key is optional. They all live under `[tools.giolt]`:

```toml
[tools.giolt]
entry = "my_app/server"
assets = "public"
outdir = "./dist"
esbuild_args = ["--external:node:crypto"]
spa = false
watch = ["src", "content"]
port = 3000
live_reload = true
api_url = "https://dash.giolt.com"
prebuild = "gleam run -m docs/build"
```

- **`entry`** — defaults to your package name. The module that exports `handle`, such
  as `my_app/server`. It has to be a Gleam module name, not a file path.
- **`assets`** — defaults to none. A directory copied into the output as static assets.
  `dev` serves it directly and watches it.
- **`outdir`** — defaults to `./dist`. Where the bundle goes. It is deleted before every
  build, so `.`, `/` and `..` are refused.
- **`esbuild_args`** — defaults to `[]`. Raw esbuild flags appended after Giolt's own.
  Later flags win, so this is how you override a default (`--minify=false`) or mark
  something `--external` so esbuild doesn't bundle it a second time.
- **`spa`** — defaults to `false`. Sent with a deploy: serve `index.html` for any path
  that matches no file. Giolt rejects it alongside worker modules.
- **`watch`** — defaults to `["src"]`, plus `assets` when it is set. Directories `dev`
  watches. Setting it replaces the default.
- **`port`** — defaults to `3000`. The `dev` server port, from 1 to 65535.
- **`live_reload`** — defaults to `true`. Pushes browser reloads over SSE after a
  rebuild.
- **`api_url`** — defaults to `https://dash.giolt.com`. The API `deploy` talks to. The
  `GIOLT_API_URL` environment variable takes precedence.
- **`prebuild`** — defaults to none. A shell command that runs before every build,
  including each rebuild in `dev`. Use it for code generation or a static site step.

The bundle has nothing else to configure: Giolt produces one kind of artifact, a
minified, tree-shaken ESM bundle wrapped in the platform's worker entry.

## `giolt build`

```sh
gleam run --runtime bun -m giolt build
```

It runs `prebuild`, checks `handle`, runs `gleam build --target javascript`, then
bundles the compiled entry with esbuild. Giolt downloads esbuild the first time it is
needed.

## `giolt dev`

```sh
gleam run --runtime bun -m giolt dev
```

It builds once, then rebuilds on every change under `watch` and serves the result. The
server hot-reloads the worker, serves `assets` straight from disk, and reloads open
browser tabs when `live_reload` is on. A failed rebuild prints the error and the server keeps
serving the last worker it loaded.

## `giolt deploy`

```sh
export GIOLT_TOKEN=your_token_here
gleam run --runtime bun -m giolt deploy
```

- **`--preview`** — not implemented yet; the platform rejects it with a 400 ("Preview
  deployments aren't supported yet."). See [Limits](/limits).
- **`--message TEXT`** — accepted, but not sent to the platform yet.

The deploy token comes from the `GIOLT_TOKEN` environment variable, the one place the
CLI reads your environment besides `GIOLT_API_URL`. There is no `.env` loading.

Module paths starting with `__giolt` are reserved and rejected — the platform's own
metering shim uses that prefix.

### How a deploy is split

Everything under `<outdir>/static/` uploads as a static asset, everything else uploads
as a Worker module. `assets` places your files under `static/` for you, and `giolt
build` always adds the worker module outside it. An assets-only deploy, with no Worker
script, is not possible from the CLI yet.

## Erlang target

A project with `target = "erlang"` builds for GlowVM. `giolt build` needs Erlang/OTP and
rebar3 installed and tells you which one is missing. `dev` and `deploy` do not support
this target yet. See [How to use GlowVM](/glowvm/how-to-use).

## Next steps

- [Get started](/get-started) for a full walkthrough from a new project.
- [Report an issue](https://github.com/withgiolt/issues) if something's broken or
  missing.
