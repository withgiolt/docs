set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

default:
    @just --list

# Build, watch and serve the site on http://localhost:3000
dev $NODE_ENV="development":
    gleam run --runtime bun -m giolt dev

check:
    gleam format --check
    bun fmt --check
    gleam build

format:
    gleam format
    bun fmt

# Run once per clone: formats staged work on every commit so CI's format check passes.
hooks:
    git config core.hooksPath .githooks

# Generate the site into ./dist/static
build:
    gleam run --runtime bun -m giolt build

# Build and ship ./dist/static to Giolt. Needs GIOLT_TOKEN, an API token with the deploy scope.
deploy:
    gleam run --runtime bun -m giolt deploy
