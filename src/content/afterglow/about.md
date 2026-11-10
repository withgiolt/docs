---
title = "About afterglow"
---

# About afterglow

afterglow is Giolt's runtime for Gleam's Erlang target. It compiles your app's BEAM bytecode to
WebAssembly ahead of time and links it with a small runtime written in Rust, so the app runs as a
Cloudflare Worker. Its source is at [withgiolt/afterglow](https://github.com/withgiolt/afterglow).

> [!WARNING]
> afterglow is experimental. The runtime, the `giolt` build for it and these docs will change, so
> expect breaking changes.

New to afterglow? [How to use afterglow](/afterglow/how-to-use) walks through building an app.

## How it works

`giolt build` compiles your project to BEAM with `gleam build`, then afterglow compiles every function
your handler can reach, including the parts of OTP's `stdlib`, `kernel` and `erts` it calls, into one
`app.wasm`. Nothing interprets bytecode at request time, and one Wasm instance serves many requests.

Because the input is the same BEAM code that runs on Erlang/OTP, integers have arbitrary precision,
binaries and bitstrings match the way they do on the BEAM, and `gleam_stdlib` behaves as it does on
Erlang. afterglow's tests compare its output with real `erl`.

## Limitations

- **Missing functions.** Some OTP functions and NIFs aren't in afterglow yet. `giolt build` lists the
  ones your app reaches and still builds. A request that calls one gets a 500 whose body names it,
  such as `{"error":"afterglow does not implement crypto:mac/4"}`.
- **`crypto`:** only `crypto:strong_rand_bytes/1`. `crypto:hash/2` and `crypto:mac/4` are missing, so
  `gleam_crypto` hashing and HMAC, and wisp's signed cookies and sessions, don't work yet.
- **No `ets` and no `re`.** Libraries that use ETS tables or regular expressions (`gleam_regexp`)
  fail with a missing-function 500.
- **`erlang:phash2`** returns different values from Erlang/OTP, and small maps with atom keys can
  iterate in a different order.
- **Deep recursion.** Non-tail recursion deeper than about 12,000 calls overflows the stack. That
  request gets a 502 and the next one works.
- **Request-scoped processes.** You can spawn processes and send messages within a request, but they
  end with it. Processes aren't preempted: one that loops without receiving blocks the others.
- **No file responses.** A `wisp.File` body returns 501.
- **No OS access:** no ports, `os:cmd/1`, distributed Erlang or hot code loading, and no file system.
- **No outbound HTTP** from Erlang code yet.

The planned fixes are tracked in
[withgiolt/afterglow#2](https://github.com/withgiolt/afterglow/issues/2).

## Practical guidance

- **Read the build output.** The list of missing functions tells you which code paths will fail
  before a request hits them.
- **Prefer pure Gleam and pure Erlang dependencies.** NIF-backed libraries are the most likely to be
  missing.
- **Keep state outside the request**, in a database or KV store.

Have a use case that needs something not listed here? Open an issue in
[withgiolt/afterglow](https://github.com/withgiolt/afterglow/issues).
