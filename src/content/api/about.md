---
title = "API overview"
---

# API overview

The Giolt API is what the `giolt` CLI and the dashboard use to manage projects. You can
call it yourself from scripts. Every route takes and returns JSON.

```
https://dash.giolt.com/api/v1
```

- [Projects](/api/projects): list, create, rename and delete projects, and read your
  account and usage.
- [Deploy](/api/deploy): upload a new version of a project.

Timestamps are RFC 3339 strings in UTC, such as `2026-11-03T11:35:05Z`.

## Authentication

Send a token in the `Authorization` header on every request:

```sh
curl https://dash.giolt.com/api/v1/me \
  -H "Authorization: Bearer $GIOLT_TOKEN"
```

There are three kinds of credential:

| Credential  | Made by                                                    | Acts on                         |
| ----------- | ---------------------------------------------------------- | ------------------------------- |
| Login token | `giolt login`                                              | every project in your account   |
| API token   | the [Tokens](https://dash.giolt.com/tokens) dashboard page | every project in your account   |
| Deploy key  | each project's page in the dashboard                       | deploying that one project only |

Login and API tokens start with `giolt_`. Both are tied to your account and carry a
set of scopes. A login token expires after 90 days. An API token expires after 30, 90 or
365 days, or never, as you choose when you create it. You can revoke either kind on the
Tokens page, and `giolt logout` revokes its own login token. The dashboard shows a token
once, when it is created.

A deploy key works only for deploying its own project; every other route answers `403`.

Tokens are managed only in the dashboard. No API route creates, lists or revokes other
tokens, so a leaked token can't be used to make more.

### Scopes

| Scope            | Allows                                   |
| ---------------- | ---------------------------------------- |
| `projects:read`  | listing and reading projects, and usage  |
| `projects:write` | creating, renaming and deleting projects |
| `deploy`         | deploying any project in the account     |

`giolt login` asks for all three. For CI, create an API token with `deploy` only, or use
the project's deploy key.

### Signing in from a terminal

`giolt login` uses a device flow, which other clients can use too:

1. `POST /api/v1/auth/device` with no body. The response holds a `device_code`, a
   `user_code`, a `verification_url`, `expires_in` (seconds) and `interval` (seconds).
2. Open `verification_url` in a browser, sign in to Giolt, check that the code shown
   matches `user_code`, and approve.
3. Poll `POST /api/v1/auth/device/token` with `{ "device_code": "..." }`, waiting
   `interval` seconds between requests. It answers:

   | Status | Error `code`            | Meaning                                           |
   | ------ | ----------------------- | ------------------------------------------------- |
   | 200    |                         | approved: the body holds `token` and `expires_at` |
   | 428    | `authorization_pending` | not approved yet; keep polling                    |
   | 429    | `slow_down`             | polling too often; wait longer between requests   |
   | 410    | `expired_token`         | the code expired; start again from step 1         |
   | 403    | `access_denied`         | the request was declined                          |

A device code is valid for 10 minutes and can be used once.

To sign out, `DELETE /api/v1/auth/token` revokes the token that sent the request and
returns `204`. A deploy key gets `403`.

## Errors

Every error response has the same body:

```json
{
  "error": {
    "code": "project_limit",
    "message": "You've reached the limit of 5 projects."
  }
}
```

`code` doesn't change between releases, so match on it. `message` is written for people
and is safe to show as it is.

| Status | `code`                                               | When                                                                  |
| ------ | ---------------------------------------------------- | --------------------------------------------------------------------- |
| 400    | `invalid_request`, `invalid_slug`, `not_implemented` | the body is malformed, or asks for something not built yet            |
| 401    | `unauthorized`                                       | the token is missing, unknown, expired or revoked                     |
| 402    | `billing_required`                                   | the account has no active subscription                                |
| 403    | `forbidden`                                          | the token lacks the scope, or a deploy key is used on another project |
| 404    | `not_found`                                          | no such project in your account                                       |
| 409    | `slug_taken`, `slug_reserved`, `project_limit`       | the name is in use or reserved, or you have 5 projects                |
| 413    | `payload_too_large`                                  | the deploy is over a size limit                                       |
| 405    | `method_not_allowed`                                 | the path exists but not with this method; see the `Allow` header      |
| 502    | `upstream_failed`                                    | Giolt couldn't finish the change; the `message` says whether to retry |

A project that belongs to another account answers `404`, the same as one that doesn't
exist.

### Billing

Creating, renaming, deleting and deploying need an active subscription and return `402
billing_required` without one. The message includes the link to fix it. Reading your
account, projects and usage always works, so you can still see what you have.

## Pagination

List routes return `{ "data": [...] }` and aren't paginated yet: an account holds at
most 5 projects. A cursor field may be added later; clients that ignore unknown fields
won't need to change.
