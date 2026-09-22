# docs

The Giolt documentation site, built with Gleam + Lustre — and hosted on Giolt
itself.

## Requirements

- [Just](https://just.systems)
- [Gleam](https://gleam.run)
- [Deno](https://deno.com) (only to install the Tailwind/daisyUI packages)

```sh
gleam deps download
deno ci
```

## Working on it

```sh
just dev     # http://localhost:3000, rebuilds and live-reloads on change
just build   # generate the site and bundle it for Giolt into ./dist
just check   # format check and type check
just format
```

## How it is put together

`src/build.gleam` does three things in order:

1. Renders `src/content/**.md` into a static site under `./build/tmp/static`
   with `lustre_ssg`, copying `./public` in alongside it.
2. Builds `./src/docs.css` into that same directory with Tailwind.
3. Runs `giolt_sdk/bundle` over `src/docs.gleam`, which writes the worker to
   `./dist/index.mjs` and copies the generated site to `./dist/static`.

The site is static, and Giolt serves assets before the worker sees a request —
so `src/docs.gleam` only ever handles what matched no file, which makes it the
404 page and nothing more.

The staging directory is deliberately not `./dist`: `bundle.run` wipes its
output directory on every build, so anything written there first would be thrown
away.

## Deploying

`main` deploys through `.github/workflows/deploy.yml`, running the same thing
you can run locally:

```sh
GIOLT_TOKEN=... just deploy
```

A Giolt project is served at `<slug>.giolt.app`. Pointing docs.giolt.com at it
is a DNS/route step outside the platform, for as long as Giolt has no custom
domains.

Pull requests run `just check` and `just build` through
`.github/workflows/check.yml`. They are not deployed anywhere: Giolt has no
preview deployments yet.

`src/deploy.gleam` is the builder chain from [/sdk](https://docs.giolt.com/sdk),
configured from the environment:

- `GIOLT_TOKEN` — the project's deploy key from the Giolt dashboard. In CI it
  comes from the `GIOLT_TOKEN` repository secret; locally a `.env` works.
- `GIOLT_PROJECT_ID` — the project id.
- `GIOLT_API_URL` — the API to deploy against, defaulting to
  `https://dash.giolt.com`. Useful when running against a local Giolt.

> Deploys do not go out yet. `giolt_sdk/deploy` builds a plan and then returns
> `NotImplemented` — "giolt_sdk/deploy does not talk to the Giolt API yet." — so
> `just deploy` fails there. Everything up to that point works: the bundle is
> built and the plan is complete. The deploy API itself is live and takes the
> deploy key as a bearer token at `POST /api/deploy`.

Found a bug or have a request? File it in
[withgiolt/issues](https://github.com/withgiolt/issues), the central issue
tracker for all Giolt projects.
