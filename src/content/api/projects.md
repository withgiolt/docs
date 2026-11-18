---
title = "Projects"
---

# Projects

Routes for your account and its projects. All of them live under
`https://dash.giolt.com/api/v1` and need a login or API token; see
[API overview](/api/about).

## The project object

```json
{
  "id": 42,
  "slug": "my-app",
  "url": "https://my-app.giolt.app",
  "suspended": false,
  "created_at": "2026-11-03T07:00:00Z",
  "updated_at": "2026-11-03T07:00:00Z",
  "latest_deployment": {
    "id": "…",
    "url": "https://my-app.giolt.app",
    "status": "live",
    "created_at": "2026-11-03T07:05:00Z"
  }
}
```

- **`id`** — a number that never changes. Routes address a project by `id`, so store
  this rather than the slug.
- **`slug`** — the project's name, and the first part of its URL. The CLI calls it the
  project name.
- **`suspended`** — `true` while the account's subscription is inactive. A suspended
  project serves a placeholder page until billing is current again.
- **`latest_deployment`** — `null` until the first deploy. Its `status` is `live` while
  it serves the project, `ready` once a newer deploy has replaced it, and `suspended`
  while the project is offline for an unpaid balance.

A slug is 3 to 63 characters of lowercase letters, digits and hyphens, and can't start
or end with a hyphen. Some names are reserved and answer `409 slug_reserved`.

## Get the signed-in account

```
GET /api/v1/me
```

Any valid token works, whatever its scopes. This is what `giolt whoami` prints. `email`
is `null` when Giolt can't look it up at that moment.

```json
{
  "user": { "id": "…", "email": "you@example.com" },
  "token": {
    "name": "giolt login",
    "scopes": ["projects:read", "projects:write", "deploy"],
    "expires_at": "2027-02-01T07:00:00Z"
  }
}
```

## List projects

```
GET /api/v1/projects
```

Scope: `projects:read`.

```sh
curl https://dash.giolt.com/api/v1/projects \
  -H "Authorization: Bearer $GIOLT_TOKEN"
```

Returns `{ "data": [project, ...] }`. Add `?slug=my-app` to find a project by name: `data`
then holds the one match, or nothing, including when the name isn't a valid slug.

## Get a project

```
GET /api/v1/projects/{id}
```

Scope: `projects:read`. Returns the project, or `404 not_found`.

## Create a project

```
POST /api/v1/projects
```

Scope: `projects:write`. Needs an active subscription.

```sh
curl https://dash.giolt.com/api/v1/projects \
  -H "Authorization: Bearer $GIOLT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "slug": "my-app" }'
```

| Field  | Type   | Required | Notes                                 |
| ------ | ------ | -------- | ------------------------------------- |
| `slug` | string | yes      | the project name; see the rules above |

Returns `201` with the new project. The project has no deployment yet; see
[Deploy](/api/deploy). A project isn't tied to a Gleam target: each deploy can be either one. A
`target` field in the body is ignored.

| Status | `code`                        | When                               |
| ------ | ----------------------------- | ---------------------------------- |
| 400    | `invalid_request`             | the body is malformed              |
| 400    | `invalid_slug`                | the slug breaks the rules above    |
| 409    | `slug_taken`, `slug_reserved` | the name isn't available           |
| 409    | `project_limit`               | the account already has 5 projects |

## Rename a project

```
PATCH /api/v1/projects/{id}
```

Scope: `projects:write`. Needs an active subscription.

```sh
curl -X PATCH https://dash.giolt.com/api/v1/projects/42 \
  -H "Authorization: Bearer $GIOLT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "slug": "my-new-name" }'
```

Returns the renamed project. Renaming changes the project's URL straight away:
`my-new-name.giolt.app` serves the current deployment, and the old address stops
working, with no redirect. Errors are the same as for create, without `project_limit`.

If the new name is saved but Giolt can't move the URL, the rename answers `502
upstream_failed` with the message "Saved, but the new URL won't work until you deploy
again." Don't retry the rename; deploy the project instead.

## Delete a project

```
DELETE /api/v1/projects/{id}
```

Scope: `projects:write`. Needs an active subscription.

Returns `204` with no body. Deleting is immediate and permanent: the project, its
deployments and its URL are gone, and there is no undo or grace period.

## Environment variables

A project holds up to 64 environment variables. A name is upper case letters, digits
and `_`, at most 64 characters, and can't start with a digit or with `GIOLT_`. A value
is at most 5,120 bytes of UTF-8, with no NUL character. A change reaches the app on
its next deploy, and only if the deploy lists the name in [`env`](/api/deploy).

### List variables

```
GET /api/v1/projects/{id}/env
```

Scope: `projects:read`.

```json
{
  "data": [
    {
      "name": "REGION",
      "secret": false,
      "value": "eu",
      "updated_at": "2026-11-18T10:00:00Z"
    },
    {
      "name": "API_KEY",
      "secret": true,
      "value": null,
      "updated_at": "2026-11-18T10:00:00Z"
    }
  ]
}
```

A secret's `value` is always `null`. Nothing in the API or the dashboard shows it
again after it is set.

### Set a variable

```
PUT /api/v1/projects/{id}/env/{name}
```

Scope: `projects:write`.

```sh
curl -X PUT https://dash.giolt.com/api/v1/projects/42/env/API_KEY \
  -H "Authorization: Bearer $GIOLT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "value": "…", "secret": true }'
```

`secret` is optional and defaults to `false`. Setting a name that exists replaces its
value. The response is `200` with `{ "name": "API_KEY", "secret": true }`, without the
value.

| Status | `code`              | When                                                                       |
| ------ | ------------------- | -------------------------------------------------------------------------- |
| 400    | `invalid_request`   | a bad name or body, or a value holding a NUL character or a lone surrogate |
| 409    | `env_var_limit`     | adding a new name when the project already has 64 variables                |
| 413    | `payload_too_large` | the value is over 5,120 bytes                                              |

### Delete a variable

```
DELETE /api/v1/projects/{id}/env/{name}
```

Scope: `projects:write`. Returns `204` with no body, or `404 not_found` when the
project has no variable with that name. The live deployment keeps the value until the
next deploy.

## Read usage

```
GET /api/v1/usage
```

Scope: `projects:read`. Usage is counted for the whole account, not per project.

```json
{
  "requests": 1234,
  "included": 1000000,
  "period_start": "2026-11-01T00:00:00Z",
  "period_end": "2026-12-01T00:00:00Z"
}
```

`requests` is the number of requests served across all your projects in the current
billing period, which runs from `period_start` to `period_end`. `included` is how many
requests your plan covers each period.

An account that hasn't subscribed yet has used nothing: `requests` is `0` and both dates
are `null`.

Reading usage needs a token with the `projects:read` scope.
