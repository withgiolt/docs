---
title = "Deploy from CI"
---

# Deploy from CI

CI has no browser to approve `giolt login`, so give it a token through the
`GIOLT_TOKEN` environment variable instead. `giolt deploy` uses `GIOLT_TOKEN` whenever it
is set.

## 1. Link the project

Run this once on your own machine and commit the change, so CI knows which project to
deploy:

```sh
gleam run -m giolt link my-app
```

## 2. Create a token

Create an API token with the `deploy` scope on the dashboard's
[Tokens](https://dash.giolt.com/tokens) page and give it only `deploy`. It can deploy
any project in your account, so one token covers several projects. It expires after
the time you choose, unless you choose never. To replace a token, use Rotate on the
same page: it makes a copy with the same scopes and expiry and revokes the old one.

Store it as a secret in your CI provider, never in the repository.

## 3. Deploy

Make the secret available as `GIOLT_TOKEN` and run:

```sh
gleam run -m giolt deploy
```

For example, on GitHub Actions:

```yaml
- name: Deploy
  run: gleam run -m giolt deploy
  env:
    GIOLT_TOKEN: ${{ secrets.GIOLT_TOKEN }}
```

The job needs Gleam and Node 20 or newer installed, the same as on your machine.

To deploy a project other than the linked one, pass `--project NAME`.

A failed deploy exits non-zero, so the job fails with it. See [Limits](/limits) for
what isn't supported yet.
