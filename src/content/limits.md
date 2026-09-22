---
title = "Limits"
---

# Limits

What Giolt doesn't do yet, and the hard limits that apply to what it does. Everything
here applies to the JavaScript-target platform; see [About GlowVM](/glowvm/about) for
GlowVM's own (much longer) list.

## Not yet supported

- **Environment variables & bindings.** Deployed Workers carry no bindings at all — no
  env vars, no KV/D1/R2, no secrets. Nothing you deploy can read anything from `env`.
  Planned, not started.
- **Custom domains.** Every project gets `<slug>.giolt.app`; there's no way to attach
  your own domain yet. In progress.
- **Preview deployments & rollbacks.** `deploy.preview(True)` is rejected with a 400
  ("Preview deployments aren't supported yet.") — every deploy ships straight to
  production, and there's no rollback beyond deploying an older build again yourself.
  Planned.
- **CI integration.** Nothing beyond running the SDK's scripts yourself — no GitHub
  Actions/GitLab CI integration yet. Planned.

## Hard limits

- **5 projects per account.** Creating a 6th fails outright; there's no way to raise
  this today.
- **Module paths starting with `__giolt` are reserved** and rejected at deploy (400
  "Module path uses a reserved name") — the platform's own metering shim uses that
  prefix internally.

## Billing & usage

Deploying requires an active subscription ($5/month, 1,000,000 requests included, then
$0.50 per additional million). If the subscription lapses, every route on the project —
including ones a static asset used to serve — starts returning a 402 placeholder page
until it's resumed; nothing is deleted, and the project's own content serves again as
soon as billing is current. See your usage any time in the dashboard under Settings.
