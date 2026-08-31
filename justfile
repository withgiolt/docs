default:
    @just --list

dev:
    deno task wrangler dev --live-reload

check:
    gleam check
    deno check

format:
    gleam format
    deno fmt

build:
    gleam run -m build
