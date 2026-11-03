default:
    @just --list

# Build, watch and serve the site on http://localhost:3000
dev:
    NODE_ENV=development gleam dev

check:
    gleam check
    bun fmt --check

format:
    gleam format
    bun fmt

# Generate the site and bundle it for Giolt into ./dist
build:
    gleam run -m build

# Ship ./dist to Giolt. Needs GIOLT_TOKEN (the project's deploy key).
deploy:
    gleam run -m deploy
