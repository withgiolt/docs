---
title = "For coding agents"
---

# For coding agents

Giolt hosts Gleam projects. This page is the short version of the docs for a coding agent,
written for the JavaScript target. The Erlang target is experimental; see
[How to use afterglow](/afterglow/how-to-use). The same text is served as plain text at
[docs.giolt.com/llms.txt](https://docs.giolt.com/llms.txt), followed by an index of every
page.

## Install

Needs Gleam and Node 20 or newer, or Bun. For the JavaScript target, the project needs
`target = "javascript"` in `gleam.toml`.

```sh
gleam add --dev giolt
gleam add conversation
```

Run the CLI with `gleam run -m giolt <command>`. Add `--runtime bun` to use Bun.

## Handler

The entry module exports `handle`. It defaults to the package's own module. Use the
`conversation` types exactly, because a plain `String` body is served as its first
character only.

```gleam
import conversation
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}

pub fn handle(
  _request: Request(conversation.RequestBody),
) -> Response(conversation.ResponseBody) {
  response.new(200)
  |> response.set_body(conversation.Text("Hello from Giolt!"))
}
```

## Authenticate

- On a developer machine, run `gleam run -m giolt login`. It opens a browser for the
  user to approve, so ask the user to run it.
- In CI or any shell with no browser, set `GIOLT_TOKEN` to an API token with the `deploy`
  scope. The user creates it on the dashboard Tokens page. No API route creates tokens.
- Creating a project and deploying need an active subscription. Without one the API
  answers `402 billing_required`.

## Deploy

```sh
gleam run -m giolt projects create my-app
gleam run -m giolt link my-app
gleam run -m giolt deploy
```

`link` writes `project = <id>` into `gleam.toml`. `deploy` builds first, then uploads
`./dist`, and ships straight to production. The project is live at `my-app.giolt.app`.

## Verify

- `gleam run -m giolt build` checks that `handle` exists and has the right type, and
  prints the expected and found types when it doesn't.
- `gleam run -m giolt dev` serves the build on `localhost:3000`.
- After a deploy, request `https://my-app.giolt.app`.
- `gleam run -m giolt usage` shows request usage for the billing period.

## Not supported

- **Rollback.** There is none. Deploy an older build again.
- **Preview deployments.** `giolt deploy --preview` fails with a 400.
- **Environment variables and bindings.** A deployed project can read nothing from
  `env`. `GIOLT_TOKEN` and `GIOLT_API_URL` configure the CLI only.
- **Custom domains.** Every project is `<slug>.giolt.app`.
- **Reserved paths.** Module and asset paths starting with `__giolt` are rejected.
- **Limits.** 5 projects per account, 5,000 files and 32 MiB per deploy, 10 MiB per
  file.
- **afterglow.** Projects targeting `erlang` build with afterglow, which is experimental.
  `giolt deploy` works for them and `giolt dev` doesn't yet. See
  [About afterglow](/afterglow/about).

## Errors

A failed CLI command exits non-zero. Every API error has this body, and `code` is stable
while `message` is for people:

```json
{
  "error": {
    "code": "project_limit",
    "message": "You've reached the limit of 5 projects."
  }
}
```

Match on `code`. A `429 rate_limited` response carries a `Retry-After` header with the
seconds to wait. A `502 upstream_failed` means Giolt couldn't finish the change, and the
`message` says whether to retry. The full list is in the [API overview](/api/about#errors).

## AGENTS.md snippet

Copy this into the `AGENTS.md` of a project that deploys to Giolt:

```markdown
## Deploying to Giolt

- Run the CLI as `gleam run -m giolt <command>`: `build`, `dev`, `deploy`, `usage`.
- Deploy with `gleam run -m giolt deploy`. It builds first and ships to production.
- Don't run `giolt login`. It needs a browser. Ask me, or use `GIOLT_TOKEN`.
- Handlers use `conversation` types and export `handle`.
- There is no rollback, no preview deploy and no environment variables.
- Docs for agents: https://docs.giolt.com/llms.txt
```
