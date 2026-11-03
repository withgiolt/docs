---
title = "Projects"
---

# Projects

Routes for your account and its projects. All of them live under
`https://dash.giolt.com/api/v1` and need a login or API token; see
[API overview](/api/about). A deploy key can't call them.

## The project object

```json
{
  "id": 42,
  "slug": "my-app",
  "url": "https://my-app.giolt.app",
  "target": "javascript",
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
- **`target`** — `javascript`. `erlang` is not supported for deploys yet.
- **`suspended`** — `true` while the account's subscription is inactive. A suspended
  project serves a placeholder page until billing is current again.
- **`latest_deployment`** — `null` until the first deploy. Its `status` is `live` while
  it serves the project, `ready` once a newer deploy has replaced it, and `suspended`
  while the project is offline for an unpaid balance.

A slug is 3 to 63 characters of lowercase letters, digits and hyphens, and can't start
or end with a hyphen. Some names are reserved and answer `409 slug_reserved`.

The API never returns a project's deploy key. Copy it from the dashboard.

## Get the signed-in account

```
GET /api/v1/me
```

Any valid token works, whatever its scopes. This is what `giolt whoami` prints.

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
then holds the one match, or nothing.

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

| Field    | Type   | Required | Notes                                 |
| -------- | ------ | -------- | ------------------------------------- |
| `slug`   | string | yes      | the project name; see the rules above |
| `target` | string | no       | defaults to `javascript`              |

Returns `201` with the new project. The project has no deployment yet; see
[Deploy](/api/deploy).

| Status | `code`                        | When                               |
| ------ | ----------------------------- | ---------------------------------- |
| 400    | `invalid_slug`                | the slug breaks the rules above    |
| 400    | `not_implemented`             | `target` is `erlang`               |
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

## Delete a project

```
DELETE /api/v1/projects/{id}
```

Scope: `projects:write`. Needs an active subscription.

Returns `204` with no body. Deleting is immediate and permanent: the project, its
deployments and its URL are gone, and there is no undo or grace period.

## Read usage

```
GET /api/v1/usage
```

Scope: `projects:read`. Usage is counted for the whole account, not per project.

```json
{
  "requests": 1234,
  "period_start": "2026-11-01T00:00:00Z",
  "period_end": "2026-12-01T00:00:00Z"
}
```

`requests` is the number of requests served across all your projects in the current
billing period, which runs from `period_start` to `period_end`.
