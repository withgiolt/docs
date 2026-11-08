---
title = "CLI"
---

# CLI

`giolt` is a Gleam package you run with `gleam run -m giolt <command>`. It builds,
runs and deploys your app, and it reads its configuration from `[tools.giolt]` in your
own `gleam.toml`, so there are no scripts to keep in sync. It runs on Node 20 or newer,
which is Gleam's default JavaScript runtime, and on Bun; add `--runtime bun` to run it
on Bun.

## Installation

```sh
gleam add --dev giolt
```

Or install it globally from npm, so you can type `giolt <command>` instead of
`gleam run -m giolt <command>`. It needs Node 20 or newer:

```sh
npm i -g @giolt/cli
giolt build
```

`npx @giolt/cli <command>` runs it once without installing. With Bun, use
`bun i -g @giolt/cli`; the installed script starts with `#!/usr/bin/env node`, so the
machine still needs Node, or you can run `bunx --bun @giolt/cli <command>` instead.

Everything on this page works the same either way. Examples write
`gleam run -m giolt <command>`; with the global install, run `giolt <command>`. The
global install also reads `-h` and `--help` itself, so `giolt -h` works, unlike
`gleam run -m giolt -h`.

For a walkthrough from a fresh project, see [Get started](/get-started).

## Commands

| Command                                                                      | What it does                                                                                              |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `giolt build [--config FILE]`                                                | Checks `handle`, compiles and bundles into `outdir`.                                                      |
| `giolt dev [--config FILE]`                                                  | Builds, watches, serves on `port` and reloads on change. JavaScript target only, except for static sites. |
| `giolt deploy [--project NAME] [--preview] [--artifact DIR] [--config FILE]` | Builds, then uploads `outdir` to Giolt. With `artifact`, uploads that directory instead.                  |
| `giolt login [--token -]`                                                    | Signs in through the browser, or stores a dashboard token read from stdin.                                |
| `giolt logout`                                                               | Revokes the stored token and deletes it.                                                                  |
| `giolt whoami`                                                               | Shows the signed-in account, the token and where it came from.                                            |
| `giolt projects`                                                             | Lists your projects.                                                                                      |
| `giolt projects create NAME`                                                 | Creates a project.                                                                                        |
| `giolt projects rename OLD NEW`                                              | Renames a project, which changes its URL.                                                                 |
| `giolt projects delete NAME [--yes]`                                         | Deletes a project after you type its name.                                                                |
| `giolt link NAME [--config FILE]`                                            | Links this directory to a project, so `deploy` knows where to go.                                         |
| `giolt unlink [--config FILE]`                                               | Removes the link.                                                                                         |
| `giolt usage [--json]`                                                       | Shows your account's requests this billing period.                                                        |
| `giolt help`                                                                 | Prints the commands. `giolt` with no arguments does the same.                                             |
| `giolt <command> --help`                                                     | Prints that command's flags.                                                                              |

`gleam run -m giolt -h` prints help for `gleam run`, not for `giolt`, because Gleam reads
the flag first. Use `gleam run -m giolt help` instead.

A command that fails exits non-zero, so it works in CI and in scripts.

## The `handle` export

Your entry module exports one function named `handle`. On the JavaScript target:

```gleam
pub fn handle(
  request: Request(conversation.RequestBody),
) -> Response(conversation.ResponseBody) {
  // or: -> Promise(Response(conversation.ResponseBody))
}
```

On the Erlang target ([GlowVM](/glowvm/how-to-use)):

```gleam
pub fn handle(request: wisp.Request) -> wisp.Response
```

`giolt build` reads the types from `gleam export package-interface` and fails with a
clear message when `handle` is missing, still named `handler`, takes the wrong number of
parameters or has the wrong types. The generated worker also checks at request time, so
a bundle you produced another way still gets a clear 500 instead of a crash.

Deployed projects carry no bindings. See
[Limits](/limits) for this and everything else not supported yet.

## Configuration

Every key is optional. They all live under `[tools.giolt]`:

```toml
[tools.giolt]
entry = "my_app/server"
assets = "public"
outdir = "./dist"
esbuild_args = ["--external:node:crypto"]
spa = false
watch = ["src", "content"]
port = 3000
live_reload = true
api_url = "https://dash.giolt.com"
prebuild = "gleam run -m docs/build"
artifact = "./site"
project = 7
```

- **`entry`** — defaults to your package name. The module that exports `handle`, such
  as `my_app/server`. It has to be a Gleam module name, not a file path.
- **`assets`** — defaults to none. A directory copied into the output as static assets.
  `dev` serves it directly and watches it.
- **`outdir`** — defaults to `./dist`. Where the bundle goes. It is deleted before every
  build, so `.`, `/` and `..` are refused.
- **`esbuild_args`** — defaults to `[]`. Raw esbuild flags appended after Giolt's own.
  Later flags win, so this is how you override a default (`--minify=false`) or mark
  something `--external` so esbuild doesn't bundle it a second time.
- **`spa`** — defaults to `false`. Sent with a deploy: serve `index.html` for any path
  that matches no file. Giolt rejects it alongside worker modules.
- **`watch`** — defaults to `["src"]`, plus `assets` when it is set. Directories `dev`
  watches. Setting it replaces the default.
- **`port`** — defaults to `3000`. The `dev` server port, from 1 to 65535.
- **`live_reload`** — defaults to `true`. Pushes browser reloads over SSE after a
  rebuild.
- **`api_url`** — defaults to `https://dash.giolt.com`. The API `deploy` talks to. The
  `GIOLT_API_URL` environment variable takes precedence. Only used when the token
  comes from `GIOLT_TOKEN`: a stored login always goes back to the API it was created
  on, and the other commands don't read this key.
- **`prebuild`** — defaults to none. A shell command that runs before every build,
  including each rebuild in `dev`. Use it for code generation or a static site step.
- **`artifact`** — defaults to none. A directory to deploy as a static site, with no
  Worker. See [Static sites](#static-sites).
- **`project`** — defaults to none. The id of the project `deploy` ships to. `giolt link`
  writes it; you don't need to set it by hand.

The bundle has nothing else to configure: Giolt produces one kind of artifact, a
minified, tree-shaken ESM bundle wrapped in the platform's worker entry.

### More than one build in a project

`build`, `dev` and `deploy` all take `--config FILE`. Giolt then reads `[tools.giolt]` from
that TOML file instead of from `gleam.toml`. The package `name` and `target` still come from
`gleam.toml`, and any key the file leaves out falls back to its default, not to the value in
`gleam.toml`. Use it when one package has several entry modules, such as a landing page and
a dashboard:

```toml
# giolt.dash.toml
[tools.giolt]
entry = "dash"
outdir = "./dist-dash"
port = 3001
```

Give each build its own `outdir`, and don't nest one inside another: `outdir` is deleted before
every build. A different `port` lets both dev servers run at once.

```sh
gleam run -m giolt dev --config giolt.dash.toml
```

Giolt exits with an error when the file is missing, isn't valid TOML, or holds an invalid value.
A file with no `[tools.giolt]` table is not an error: every key takes its default.

## `giolt build`

```sh
gleam run -m giolt build
```

It runs `prebuild`, checks `handle`, runs `gleam build --target javascript`, then
bundles the compiled entry with esbuild. Giolt downloads esbuild the first time it is
needed.

## `giolt dev`

```sh
gleam run -m giolt dev
```

It builds once, then rebuilds on every change under `watch` and serves the result. The
server hot-reloads the worker, serves `assets` straight from disk, and reloads open
browser tabs when `live_reload` is on. A failed rebuild prints the error and the server keeps
serving the last worker it loaded.

## `giolt deploy`

```sh
gleam run -m giolt deploy
```

- **`--project NAME`** — deploy to this project instead of the linked one. The CLI
  looks the name up with your login or API token.
- **`--preview`** — not implemented yet; the platform rejects it with a 400 ("Preview
  deployments aren't supported yet."). See [Limits](/limits).
- **`--artifact DIR`** — deploy this directory as a static site, skipping the build.

`deploy` uses `GIOLT_TOKEN` when it is set, and your stored login otherwise; see Signing
in below. It picks the project from `--project`, then from the `project` key that
`giolt link` writes:

| No project set                  | Linked with `giolt link`   | `--project NAME` |
| ------------------------------- | -------------------------- | ---------------- |
| fails: link or pass `--project` | deploys the linked project | deploys `NAME`   |

A token covers your whole account, so it never names a project by itself. There is no
`.env` loading.

Module and asset paths starting with `__giolt` are reserved and rejected. The
platform's own metering code uses that prefix.

### How a deploy is split

Everything under `<outdir>/static/` uploads as a static asset, everything else uploads
as a Worker module. `assets` places your files under `static/` for you, and `giolt
build` always adds the worker module outside it. To deploy with no Worker script at all,
use `artifact`.

## Signing in

```sh
gleam run -m giolt login
```

`giolt login` prints a code and a link, and opens the link in your browser:

```
Your login code is ABCD-EFGH
Approve it at https://dash.giolt.com/device?code=ABCD-EFGH
```

Sign in to Giolt there, check that the code matches and approve it. The CLI then
prints `Logged in as you@example.com.` and where it stored the token. The token is
valid for 90 days. Logging in again replaces it and revokes the old one.

On a machine with no browser, create a token on the dashboard's
[Tokens](https://dash.giolt.com/tokens) page and pipe it in:

```sh
gleam run -m giolt login --token - < token.txt
```

`--token TOKEN` also works, but the token then ends up in your shell history. The
CLI refuses a value that doesn't start with `giolt_`.

### Where the token is kept

| System       | File                                                                             |
| ------------ | -------------------------------------------------------------------------------- |
| Linux, macOS | `$XDG_CONFIG_HOME/giolt/credentials.json`, or `~/.config/giolt/credentials.json` |
| Windows      | `%APPDATA%\giolt\credentials.json`                                               |

Only your user can read the file or its directory.

### `GIOLT_TOKEN`

When `GIOLT_TOKEN` is set, every command uses it instead of the stored token. It holds
a token made on the dashboard's [Tokens](https://dash.giolt.com/tokens) page, which is
how CI signs in; see [Deploy from CI](/ci).

### Which API the commands talk to

A stored token is always sent back to the API it was created on, and nothing
overrides that. A token from `GIOLT_TOKEN` goes to `GIOLT_API_URL` when it is set, or
to `https://dash.giolt.com`. `giolt deploy` with `GIOLT_TOKEN` also reads `api_url`,
between those two.

### `giolt whoami` and `giolt logout`

`giolt whoami` prints your email, the token's name, expiry and scopes, and whether it
came from `GIOLT_TOKEN` or the stored file. It adds the API URL when that isn't
`https://dash.giolt.com`.

`giolt logout` revokes the stored token, then deletes the file. If Giolt can't be
reached, it deletes the file anyway and warns that the token may still work: revoke it
on the [Tokens](https://dash.giolt.com/tokens) page. It never touches `GIOLT_TOKEN`.

## `giolt projects`

```sh
gleam run -m giolt projects
```

Lists each project's name, URL and latest deployment status. A project's name is the
first part of its URL: `my-app` serves at `my-app.giolt.app`. Names are 3 to 63
lowercase letters, digits and hyphens, and can't start or end with a hyphen.

```sh
gleam run -m giolt projects create my-app
gleam run -m giolt projects rename my-app my-new-name
gleam run -m giolt projects delete my-new-name
```

- **`create`** fails when the name is taken or reserved, or when you already have 5
  projects.
- **`rename`** changes the URL straight away. The old address stops serving, with no
  redirect.
- **`delete`** asks you to type the project's name to confirm. It is permanent: the
  project, its deployments and its URL are gone. `--yes` skips the prompt for scripts.
  Without a terminal to ask in and without `--yes`, it refuses.

Creating, renaming and deleting need an active subscription. Listing always works.

## `giolt link`

```sh
gleam run -m giolt link my-app
```

Looks up the project by name and writes its id as `project = 7` under `[tools.giolt]`
in `gleam.toml`, or in the `--config` file. The rest of the file, comments included, is
left as it is. Commit the change so CI deploys to the same project. `giolt link` needs a
login or an API token with the `projects:read` scope.

`giolt unlink` removes the line. The link stores the id, not the name, so renaming the
project doesn't break it.

## `giolt usage`

```sh
gleam run -m giolt usage
```

Shows how many requests your account has served in the current billing period, out of
the requests your plan includes, and the period's dates. Usage is counted for the whole
account, not per project.

```
Requests: 1234 of 1000000
Period:   2026-11-01T00:00:00Z to 2026-12-01T00:00:00Z
```

Pass `--json` to print the same fields as the [API](/api/projects) for
scripts and agents: `requests`, `included`, `period_start` and `period_end`. The dates are
`null` for an account that hasn't subscribed yet.

It needs a login or a token with the `projects:read` scope.

## Static sites

Set `artifact` to a directory and Giolt deploys it as an assets-only site: no Worker
script, no compute, requests served straight from Giolt's CDN, and no usage billed
(there's no `fetch` handler for the request meter to hook into).

```toml
[tools.giolt]
artifact = "./site"
prebuild = "gleam run -m my_site/build"
```

With `artifact` set, Giolt skips the `handle` check, `gleam build` and the bundle:

- **`giolt build`** runs `prebuild`, then checks the directory exists and is not empty.
- **`giolt deploy`** runs `prebuild`, then uploads every file in the directory as a static
  asset. You do not create a `static/` folder; `index.html` at the top of the directory
  is `index.html` at the root of the site. `--artifact DIR` overrides the key for one
  deploy.
- **`giolt dev`** runs `prebuild` on every change under `watch`, serves the directory and
  reloads the browser. Anything that matches no file is a 404.

Set `spa = true` to serve `index.html` for paths that match no file, so client-side
routes survive a refresh. Anything you want in the site has to be in the directory
already, so have `prebuild` write it there and clear the directory first if you change
where your build writes to.

## Erlang target

A project with `target = "erlang"` builds for GlowVM. `giolt build` needs Erlang/OTP and
rebar3 installed and tells you which one is missing. Run it with
`gleam run --target javascript -m giolt build`, because giolt itself runs on JavaScript. `dev`
and `deploy` do not support this target yet. See [How to use GlowVM](/glowvm/how-to-use).

## Next steps

- [Get started](/get-started) for a full walkthrough from a new project.
- [Report an issue](https://github.com/withgiolt/issues) if something's broken or
  missing.
