default:
    @just --list

# Build, watch and serve the site on http://localhost:3000
dev:
    gleam dev

check:
    gleam check
    deno check

format:
    gleam format
    deno fmt

# Generate the site and bundle it for Giolt into ./dist
build:
    gleam run -m build

# Ship ./dist to Giolt. Needs GIOLT_TOKEN (the project's deploy key).
deploy:
    gleam run -m deploy
