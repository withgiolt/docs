---
title = "How to use afterglow"
---

# How to use afterglow

This page walks through building a Gleam app for the Erlang target with afterglow, running the
result locally and deploying it to Giolt.

> [!WARNING]
> afterglow is experimental. You need Gleam, Erlang/OTP and rebar3 installed to build an app.
> Building works on Linux and macOS (x64 and arm64) and Windows (x64).

## 1. Add the dependencies

```toml
# gleam.toml
name = "my_app"
target = "erlang"

[dependencies]
wisp = ">= 2.2.2 and < 3.0.0"

[dev-dependencies]
giolt = ">= 0.6.0 and < 1.0.0"
```

afterglow apps are written as [wisp](https://hexdocs.pm/wisp) handlers. You don't depend on
`afterglow` yourself: the `giolt` CLI adds it when it builds your app.

## 2. Write a handler

Your entry module exports one function named `handle`:

```gleam
import wisp

pub fn handle(_req: wisp.Request) -> wisp.Response {
  wisp.ok() |> wisp.string_body("hello from afterglow")
}
```

The entry module defaults to your package's own module. If `handle` lives somewhere else, set it in
`gleam.toml`:

```toml
[tools.giolt]
entry = "my_app/server"
```

There is no `start/0` to write and nothing to register. `giolt` generates the entrypoint for you.

## 3. Build the app

`giolt` runs on JavaScript, so pass `--target javascript` even though your app targets Erlang:

```sh
gleam run --target javascript -m giolt build
```

It checks that `handle` has the right type, compiles your project to BEAM, compiles that to
WebAssembly with afterglow, and links and optimises it with Binaryen. The first build downloads
Binaryen from npm into `build/dev/bin`. If `handle` is missing or has the wrong type, the build fails
and prints the type it expected and the one it found. If Erlang/OTP or rebar3 is missing, it tells
you which.

If your app reaches functions afterglow doesn't provide, the build lists them and still succeeds.
See [About afterglow](/afterglow/about) for what that means at request time.

`dist/` contains:

- `app.wasm`: your app and the afterglow runtime, compiled to WebAssembly
- `index.mjs`: the Worker entry, which passes each request to `app.wasm` through `host.mjs`
- `host.mjs`: the code that runs `app.wasm` and converts requests and responses
- `static/`: a copy of the `assets` directory, if you set one under `[tools.giolt]`

Change the output directory with `outdir` under `[tools.giolt]`. `giolt dev` doesn't support the
Erlang target yet.

## 4. Run it locally with Bun

`index.mjs` uses `import wasm from "./app.wasm"`, which is how Cloudflare Workers load WebAssembly.
Bun needs a small plugin to do the same:

```ts
import { plugin } from "bun";
import { readFileSync } from "node:fs";

plugin({
  name: "afterglow-assets",
  setup(build) {
    build.onLoad({ filter: /app\.wasm$/ }, (args) => ({
      exports: { default: new WebAssembly.Module(readFileSync(args.path)) },
      loader: "object",
    }));
  },
});

const { default: worker } = await import("./dist/index.mjs");
const response = await worker.fetch(new Request("http://localhost/"));
console.log(response.status, await response.text());
```

```sh
bun run your_script.ts
```

## 5. Deploy it

```sh
gleam run --target javascript -m giolt deploy
```

`giolt deploy` builds the app and uploads `dist/` the same way it uploads a JavaScript app. Files in
`static/` are served before requests reach your app, so put images, CSS and other static files in
the `assets` directory rather than serving them with `wisp.serve_static`: the Wasm build has no
file system to read them from.

## Environment variables

The string values in the second argument of `fetch` become your app's environment, so `envie` reads
them as usual. Giolt doesn't pass environment variables to deployed apps yet. Locally, pass them
yourself, for example `worker.fetch(request, { SECRET_KEY: "secret" })`:

```gleam
import envie
import wisp

pub fn handle(_req: wisp.Request) -> wisp.Response {
  let secret = envie.get_string("SECRET_KEY", "NONE")
  wisp.ok() |> wisp.string_body(secret)
}
```

## Next steps

Read [About afterglow](/afterglow/about) for what works today and what doesn't.
