---
title = "How to use GlowVM"
---

# How to use GlowVM

This page walks through packing a Gleam (Erlang target) app with GlowVM and running it on a WASI host
such as a WASI-compatible JS runtime.

> [!WARNING]
> GlowVM is experimental. You need Gleam, Erlang/OTP and rebar3 installed to build an app.

## 1. Add the dependencies

```toml
# gleam.toml
name = "my_app"
target = "erlang"

[dependencies]
wisp = ">= 2.2.2 and < 3.0.0"

[dev-dependencies]
giolt = ">= 0.1.0 and < 1.0.0"
```

GlowVM apps are written as [wisp](https://hexdocs.pm/wisp) handlers. You do not depend on `glowvm`
yourself: the `giolt` CLI adds the runtime when it builds your app.

## 2. Write a handler

Your entry module exports one function named `handle`:

```gleam
import wisp

pub fn handle(_req: wisp.Request) -> wisp.Response {
  wisp.ok() |> wisp.string_body("hello from glowvm")
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

It checks that `handle` has the right type, compiles your project, packs it into an AtomVM PackBeam
and writes everything a WASI host needs into `./dist`. If `handle` is missing, still named
`handler`, or has the wrong type, the build fails and prints the type it expected and the one it
found. If Erlang/OTP or rebar3 is missing, it tells you which.

`dist/` contains:

- `app.avm` — your compiled BEAM modules, packed as an AtomVM PackBeam
- `glowvm.wasm` — the AtomVM runtime compiled to `wasm32-wasi`
- `index.js` / `index.min.js` — the WASI host glue, ready to use as a WASI host entrypoint

Change the output directory with `outdir` under `[tools.giolt]`. `giolt dev` and `giolt deploy` do
not support the Erlang target yet.

## 4. Run it locally with Bun

`index.js` uses `import wasm from "./glowvm.wasm"` and `import avm from "./app.avm"`, which is
a bundler-level import convention and has no native meaning to Bun. A small plugin supplies the same values:

```ts
import { plugin } from "bun";
import { readFileSync } from "node:fs";

plugin({
  name: "glowvm-assets",
  setup(build) {
    build.onLoad({ filter: /glowvm\.wasm$/ }, (args) => ({
      exports: { default: new WebAssembly.Module(readFileSync(args.path)) },
      loader: "object",
    }));
    build.onLoad({ filter: /app\.avm$/ }, (args) => ({
      exports: { default: readFileSync(args.path) },
      loader: "object",
    }));
  },
});

const { default: worker } = await import("./dist/index.js");
const response = await worker.fetch(new Request("http://localhost/"));
console.log(response.status, await response.text());
```

```sh
bun run your_script.ts
```

Any other WASI-compliant JS runtime works the same way, as long as it can supply `env` and
`wasi_snapshot_preview1` imports to the `glowvm.wasm` module — see
[About GlowVM](/glowvm/about) for what those cover.

## Environment variables

`envie` reads environment variables through GlowVM's `env` shim:

```gleam
import envie
import wisp

pub fn handle(_req: wisp.Request) -> wisp.Response {
  let secret = envie.get_string("SECRET_KEY", "NONE")
  wisp.ok() |> wisp.string_body(secret)
}
```

## Next steps

Read [About GlowVM](/glowvm/about) for what's supported today, current limitations, and the
roadmap.
