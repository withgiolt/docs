default:
    @just --list

# Build, watch and serve the site on http://localhost:3000
dev:
    NODE_ENV=development gleam run --runtime bun -m giolt dev

check:
    gleam check
    bun fmt --check

format:
    gleam format
    bun fmt

# Generate the site into ./dist/static
build:
    gleam run --runtime bun -m giolt build

# Build and ship ./dist/static to Giolt. Needs GIOLT_TOKEN (the project's deploy key).
deploy:
    gleam run --runtime bun -m giolt deploy
