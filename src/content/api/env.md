---
title = "Environment variables"
---

# Environment variables

Routes for a project's environment variables and secrets. All of them live under
`https://dash.giolt.com/api/v1` and need a login or API token; see
[API overview](/api/about).

A project holds up to 64 variables. Each is either plain or a secret: a plain value can
be read back, and a secret's value is never returned after it is set. Giolt stores both
kinds encrypted.

An app receives only the variables its deploy declares, and a change reaches it on the
next deploy; see [Deploy](/api/deploy).

## The variable object

```json
{
  "name": "DATABASE_URL",
  "secret": true,
  "value": null,
  "updated_at": "2026-11-15T07:00:00Z"
}
```

- **`name`** — upper-case letters, digits and underscores, at most 64 characters. It
  can't start with a digit or with `GIOLT_`.
- **`secret`** — `true` when the value is never shown again.
- **`value`** — the value of a plain variable, and `null` for a secret.

## List variables

```http
GET /api/v1/projects/{id}/env
```

Needs the `projects:read` scope. Answers `200` with `{"data": [...]}`, sorted by name.

## Set a variable

```http
PUT /api/v1/projects/{id}/env/{name}
```

```json
{
  "value": "postgres://…",
  "secret": true
}
```

Needs the `projects:write` scope. `secret` defaults to `false`. Setting a name that
exists replaces its value and its `secret` flag. A value is at most 5,120 bytes and
can't contain a NUL character.

Answers `200` with the name and the `secret` flag, never the value:

```json
{
  "name": "DATABASE_URL",
  "secret": true
}
```

## Delete a variable

```http
DELETE /api/v1/projects/{id}/env/{name}
```

Needs the `projects:write` scope. Answers `204`. An app that was deployed with the
variable keeps it until the next deploy.

## Errors

| Status | `code`              | When                                                                  |
| ------ | ------------------- | --------------------------------------------------------------------- |
| 400    | `invalid_request`   | a malformed or reserved name, a value with a NUL, or a malformed body |
| 403    | `forbidden`         | the token lacks the scope, or the project already has 64 variables    |
| 404    | `not_found`         | no such project, or no variable with that name on delete              |
| 413    | `payload_too_large` | the value is over 5,120 bytes                                         |
| 502    | `upstream_failed`   | something went wrong on Giolt's side; retry                           |
