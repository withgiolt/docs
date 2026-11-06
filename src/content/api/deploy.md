---
title = "Deploy"
---

# Deploy

`giolt deploy` builds your project and calls this route. Call it yourself only if you
build your bundle some other way.

```
POST /api/v1/projects/{id}/deployments
```

Authenticate with a login or API token that has the `deploy` scope; see
[API overview](/api/about). Deploying needs an active subscription. A deploy goes straight to production and replaces the version
that is live.

## Request

```json
{
  "modules": [
    { "path": "index.mjs", "content_base64": "ZXhwb3J0IGRlZmF1bHQg…" }
  ],
  "assets": [
    { "path": "index.html", "content_base64": "PCFkb2N0eXBlIGh0bWw+…" }
  ],
  "spa": false
}
```

| Field     | Type    | Required | Notes                                                                     |
| --------- | ------- | -------- | ------------------------------------------------------------------------- |
| `modules` | array   | yes      | the Worker's JavaScript modules; may be empty for a static site           |
| `assets`  | array   | no       | static files, served as they are                                          |
| `spa`     | boolean | no       | serve `index.html` for paths that match no asset; static sites only       |
| `preview` | boolean | no       | `true` is rejected until preview deployments exist; see [Limits](/limits) |

Each file is `{ "path": "...", "content_base64": "..." }`, with the file's bytes
encoded as base64.

- A deploy with modules needs one at `index.mjs`, the Worker's entry.
- A deploy with no modules is a static site: its assets are served with no Worker. `spa`
  only works on these.
- Paths are compared after resolving `.` and `..`, so two paths that point at the same
  file are a duplicate.
- Paths starting with `__giolt`, in any letter case, are reserved for modules and assets
  alike. So is a path that resolves above the root, such as `../x`.

## Limits

| Limit                    | Value  |
| ------------------------ | ------ |
| Request body             | 32 MiB |
| Files (modules + assets) | 5,000  |
| One file, decoded        | 10 MiB |

Base64 makes files about a third bigger, so the body limit is reached before the files
add up to 32 MiB.

## Response

`201` with the new deployment:

```json
{
  "id": "…",
  "url": "https://my-app.giolt.app",
  "preview": false
}
```

## Errors

Errors use the shared format described in the [API overview](/api/about). The `message` names the limit or the
path that caused it.

| Status | `code`              | When                                                                                                           |
| ------ | ------------------- | -------------------------------------------------------------------------------------------------------------- |
| 400    | `invalid_request`   | invalid JSON or base64, a duplicate or reserved path, no `index.mjs`, `spa` with modules, or nothing to deploy |
| 400    | `not_implemented`   | `preview` is `true`                                                                                            |
| 402    | `billing_required`  | the account has no active subscription                                                                         |
| 403    | `forbidden`         | the token lacks `deploy`                                                                                       |
| 413    | `payload_too_large` | over one of the limits above                                                                                   |
| 502    | `upstream_failed`   | Giolt couldn't finish the deploy; try again                                                                    |

## Older CLIs

`giolt` 0.4.2 and earlier post to `POST /api/deploy` with a project deploy key. Deploy
keys and that route no longer exist, so those versions can't deploy. Update to 0.5.0 or
later and sign in with `giolt login` or a token.
