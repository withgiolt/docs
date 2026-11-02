---
title = "Get started"
---

# Get started

This walks through taking a Gleam project from nothing to deployed on Giolt: add the
`giolt` CLI, write a handler, build it, run it locally, and ship it.

## Prerequisites

- [Gleam](https://gleam.run) and [Bun](https://bun.sh) installed.
- A Gleam project targeting `javascript`. If you don't have one, create one with:

  ```sh
  gleam new my_app
  cd my_app
  ```

  Projects targeting `erlang` build for [GlowVM](/glowvm/about) instead; see
  [How to use GlowVM](/glowvm/how-to-use).

## 1. Add the CLI

```sh
gleam add --dev giolt
```

`giolt` has no scripts to scaffold. You run it with `gleam run -m giolt <command>` and
configure it, if you need to, under `[tools.giolt]` in your `gleam.toml`. Add
`--runtime bun` to run it on Bun:

```sh
gleam run --runtime bun -m giolt --help
```

## 2. Write a handler

Handlers speak [`conversation`](https://hexdocs.pm/conversation) types, so add it to
your project:

```sh
gleam add conversation
```

Giolt expects your entry module to export a single `handle` function. The entry module
defaults to your package's own module, so for a project named `my_app` that is
`src/my_app.gleam`:

```gleam
import conversation
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}

pub fn handle(
  _request: Request(conversation.RequestBody),
) -> Response(conversation.ResponseBody) {
  response.new(200)
  |> response.set_body(conversation.Text("Hello from Giolt!"))
}
```

Use these types exactly. A plain `String` body compiles, but the worker serves only its
first character.

`handle` can also return a `Promise(Response(conversation.ResponseBody))` if you need to do async work
(a database call, an outbound fetch) before responding.

If your main module already has an unrelated `handle`, point Giolt at another module:

```toml
[tools.giolt]
entry = "my_app/server"
```

## 3. Build it

```sh
gleam run --runtime bun -m giolt build
```

`giolt build` checks `handle` against your project's package interface first. If it is
missing, still named `handler`, or has the wrong type, the build stops and prints the
type it expected and the one it found. Then it compiles your project and writes
`./dist`: a minified, tree-shaken ESM bundle wrapped in the platform's worker entry.

To ship static files, put them in a directory and name it:

```toml
[tools.giolt]
assets = "public"
```

They are copied into `./dist/static`.

## 4. Run it locally

```sh
gleam run --runtime bun -m giolt dev
```

This builds, then watches `./src` (and your `assets` directory) and rebuilds on change.
It serves the result on `localhost:3000` with live reload. Change the port, the watched
directories or live reload under `[tools.giolt]`; see the [CLI reference](/cli).

## 5. Deploy it

Open your project in the [Giolt dashboard](https://dash.giolt.com) and copy its
**Deploy key**. It already resolves to exactly one project, so there's no project id
to set. Export it as the deploy token:

```sh
export GIOLT_TOKEN=your_token_here
```

```sh
gleam run --runtime bun -m giolt deploy
```

`giolt deploy` builds first, then uploads `./dist`, so it always ships exactly what you
just built. Every deploy ships straight to production — `--preview` is rejected until
preview deployments exist (see [Limits](/limits)).

Your project is live at `<slug>.giolt.app`; custom domains aren't supported yet.

Building a static site with no Worker? Set `artifact` to the directory your site is
written to; see [Static sites](/cli#static-sites).

## Next steps

- [CLI reference](/cli) — every command, every `[tools.giolt]` key, and what each one
  defaults to.
- [Limits](/limits) — what isn't supported yet, and the account limits that apply.
- [Report an issue](https://github.com/withgiolt/issues) if something's broken,
  confusing, or missing.
