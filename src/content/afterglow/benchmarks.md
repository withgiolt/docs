---
title = "afterglow benchmarks"
---

# afterglow benchmarks

This page compares how fast afterglow computes with Erlang/OTP and with Gleam's JavaScript target.
Eight workloads are written once in Gleam and run unchanged on all three. The numbers below come
from one run on one machine. They show where afterglow is close to erl and where it is far behind.

> [!WARNING]
> afterglow is an experimental research preview and not for production use. Its runtime is still
> changing, so rerun the script for current numbers.

## The run

12 November 2026, AMD Ryzen 5 3400G, Linux 7.2 x64, Erlang/OTP 29 (JIT), Node 26.13.0, afterglow
0.2.0 at commit `5e72c0c`. Each workload ran 20 untimed warm-up iterations, then 100 timed ones.

Times are the median and the 95th percentile (p95) of the timed iterations, in milliseconds. Lower
is better.

| Workload       | Input                                                          | erl            | afterglow           | Gleam JS          |
| -------------- | -------------------------------------------------------------- | -------------- | ------------------- | ----------------- |
| `fib`          | fib(27), naive recursion                                       | 2.549 / 4.010  | 4.895 / 9.568       | 2.499 / 3.677     |
| `list_reverse` | 100 reversals of a 10,000-element list                         | 3.388 / 6.313  | 11.022 / 15.805     | 11.411 / 16.050   |
| `list_sort`    | 20,000 pseudo-random Ints, `list.sort`                         | 8.333 / 12.756 | 9.525 / 14.594      | 10.654 / 17.107   |
| `json`         | 1,000 records encoded with gleam_json, then parsed and decoded | 6.124 / 11.107 | 11.210 / 16.862     | 8.404 / 12.740    |
| `string_tree`  | 20,000 numbers appended to a `string_tree`, then `to_string`   | 4.616 / 8.732  | 3.498 / 6.771       | 0.892 / 3.465     |
| `dict`         | 10,000 inserts into a `Dict`, then a lookup of every key       | 3.614 / 7.670  | 1022.126 / 1210.399 | 6.580 / 11.088    |
| `bignum`       | 1000!, then reduced modulo 1,000,000,007                       | 0.116 / 0.167  | 6.891 / 9.579       | n/a               |
| `bit_array`    | 32,768 16-bit values appended to a `BitArray`, then matched    | 0.863 / 1.356  | 3.519 / 5.606       | 355.371 / 413.541 |

erl and afterglow returned the same result for every workload. The machine was a desktop in use,
and medians moved by up to about 30% between runs, so read the ratios rather than the exact times.

## What the numbers show

- **Close to erl:** `list_sort` (1.1× erl's time) and `string_tree`, where afterglow is faster than
  erl.
- **About 2 to 4× slower than erl:** `json` (1.8×), `fib` (1.9×), `list_reverse` (3.3×) and
  `bit_array` (4.1×).
- **Far slower than erl:**
  - `dict` takes 283× as long. afterglow stores every map as one sorted array and copies it on each
    insert, so building a large `Dict` one key at a time costs time proportional to the square of
    its size. The BEAM switches to a hash tree above 32 keys.
  - `bignum` takes 59× as long. afterglow's runtime converts the operands of every multiplication
    to a separate big-integer type and back, and that conversion grows faster than the number's
    size.
- **Against Gleam JS on the same engine:** afterglow is about level on `list_reverse` and
  `list_sort`, slower on `fib`, `json` and `string_tree`, and 101× faster on `bit_array`, because
  appending to a `BitArray` on JavaScript copies it.

## How it's measured

The workloads are in
[`bench/compute/src/compute.gleam`](https://github.com/withgiolt/afterglow/blob/main/bench/compute/src/compute.gleam).
Each one takes no arguments, builds its input, does its work and returns an Int. Building the input
is part of the time, and each input is small next to the work done on it.

- **erl** times each workload in a running VM with `timer:tc`.
- **afterglow** compiles each workload into its own Wasm module. A Node script calls it once per
  iteration and times the call with `performance.now()`. Instantiating the module and resetting
  its heap between iterations aren't timed.
- **Gleam JS** is the same Gleam source compiled to JavaScript, timed in Node by the same script.

afterglow and Gleam JS run on Node, which uses V8, the engine Cloudflare Workers use. Workers don't
advance their clocks during pure computation, so timing on Workers would read zero.

The standard library and gleam_json differ per target, and that difference is part of what's
measured. JavaScript results aren't compared with erl's, because a JavaScript Int is a float.
`bignum` needs integers beyond 2^53, so it doesn't run on JavaScript.

Nothing here covers startup or requests. The afterglow repo measures those with
`bench/vs-erl.sh`.

## Run it yourself

From a clone of [withgiolt/afterglow](https://github.com/withgiolt/afterglow), with the tools its
README lists for the tests:

```sh
just bench-compute
```

`WARMUP` and `ITERS` override the iteration counts. The script prints the date, machine, versions
and inputs with the table, and fails when erl and afterglow return different results. afterglow's
CI runs it for every pull request and every push to `main`, and puts the table in the job summary.
