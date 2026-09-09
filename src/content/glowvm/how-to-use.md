---
title = "How to use GlowVM"
---

# How to use GlowVM

This page walks through packing a Gleam (Erlang target) app with GlowVM and running it on a WASI host
such as a Cloudflare Worker.

> [!WARNING]
> GlowVM is experimental and not yet published to Hex. Requires macOS or Linux to build.

## 1. Add the dependency

```toml
# gleam.toml
[dependencies]
glowvm = ">= 0.1.0 and < 1.0.0"
wisp = ">= 2.2.2 and < 3.0.0"
```

GlowVM apps are written as [wisp](https://hexdocs.pm/wisp) handlers — `glowvm.serve` takes a
`fn(wisp.Request) -> wisp.Response` and runs it as the AtomVM entrypoint.

## 2. Write a handler

```gleam
import glowvm
import wisp

pub fn start() {
  glowvm.serve(handle_request)
}

fn handle_request(_req: wisp.Request) -> wisp.Response {
  wisp.ok() |> wisp.string_body("hello from glowvm")
}
```

`start/0` is the module's entrypoint — it must take no arguments and call `glowvm.serve(handler)`.

## 3. Pack the app

`glowvm/build` compiles your project, packs it into an AtomVM PackBeam, and writes everything a
WASI host needs into an output directory:

```gleam
import glowvm/build

pub fn main() {
  build.build(output_dir: "dist", module_name: "my_app")
}
```

Run it with:

```sh
gleam run -m build
```

`module_name` is the module that exports `start/0` — usually your project's main module. Pass a
different module name to pack a different entrypoint from a project hosting several apps (one
`build.build` call per entrypoint).

This produces, in `output_dir`:

- `app.avm` — your compiled BEAM modules, packed as an AtomVM PackBeam
- `glowvm.wasm` — the AtomVM runtime compiled to `wasm32-wasi`
- `index.js` / `index.min.js` — the WASI host glue, ready to ship as a Worker entrypoint
- `app.avm.loader.mjs` / `glowvm.wasm.loader.mjs` / `deno.json` — loader helpers for running the
  bundle under Deno

## 4. Deploy to Cloudflare Workers

Point `wrangler.toml` at the generated `index.js`:

```toml
name = "test"
main = "index.min.js"
compatibility_date = "2026-08-29"
compatibility_flags = ["nodejs_compat"]

[observability]
enabled = false

[[rules]]
type = "CompiledWasm"
globs = ["**/*.wasm"]
fallthrough = true

[[rules]]
type = "Data"
globs = ["**/*.avm"]
fallthrough = true
```

```sh
npx wrangler deploy
```

`index.js` imports `glowvm.wasm` and `app.avm` next to it and exports a `fetch` handler, so no
further wiring is needed — `dist/` is deployable as-is.

## 5. Run it locally with Deno

`index.js` uses `import wasm from "./glowvm.wasm"` / `import avm from "./app.avm"`, which is
workerd's import sugar and has no native meaning to Deno. The `.loader.mjs` files GlowVM generates
exist to bridge that gap through a [Deno import
map](https://docs.deno.com/runtime/fundamentals/modules/#import-maps):

```ts
const { default: worker } = await import("./dist/index.js");
const response = await worker.fetch(new Request("http://localhost/"));
```

```sh
deno run -A --import-map=dist/deno.json your_script.ts
```

Any other WASI-compliant JS runtime works the same way, as long as it can supply `env` and
`wasi_snapshot_preview1` imports to the `glowvm.wasm` module — see
[About GlowVM](/glowvm/about) for what those cover.

## Environment variables

`envie` reads environment variables through GlowVM's `env` shim:

```gleam
import envie
import glowvm
import wisp

pub fn start() {
  glowvm.serve(handle_request)
}

fn handle_request(_req: wisp.Request) -> wisp.Response {
  let secret = envie.get_string("SECRET_KEY", "NONE")
  wisp.ok() |> wisp.string_body(secret)
}
```

## Next steps

Read [About GlowVM](/glowvm/about) for what's supported today, current limitations, and the
roadmap.
