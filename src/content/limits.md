---
title = "Limits"
---

# Limits

What Giolt doesn't do yet, and the hard limits that apply to what it does. Everything
here applies to deploys of either target; see [About afterglow](/afterglow/about) for what
afterglow itself doesn't support.

## Not yet supported

- **Environment variables & bindings.** Deployed projects carry no bindings at all.
  Nothing you deploy can read anything from `env`.
  Planned, not started.
- **Custom domains.** Every project gets `<slug>.giolt.app`; there's no way to attach
  your own domain yet. In progress.
- **Preview deployments & rollbacks.** `giolt deploy --preview` is rejected with a 400
  ("Preview deployments aren't supported yet.") — every deploy ships straight to
  production, and there's no rollback beyond deploying an older build again yourself.
  Planned.
- **CI integration.** Nothing beyond running `giolt` in your own pipeline (see
  [Deploy from CI](/ci)): no GitHub Actions or GitLab CI integration yet. Planned.

## Hard limits

- **5 projects per account.** Creating a 6th fails outright; there's no way to raise
  this today.
- **1,000,000 requests per billing period, per account.** Once an account reaches them,
  its projects go offline until the next period starts. See below.
- **10ms of CPU time per request.** A request that uses more is stopped and fails with an
  error. Time spent waiting on the network doesn't count.
- **Paths starting with `__giolt` are reserved** and rejected at deploy, for modules and
  assets alike (400 "Module path uses a reserved name" or "Asset path uses a reserved
  name").

## Billing & usage

Deploying requires an active subscription (5€/month, with 1,000,000 requests included in
each billing period). Charging for requests beyond that, planned at 1€ per additional
million, isn't live yet, so the allowance is a hard cap for now. Giolt checks usage every
15 minutes. Once the account reaches 1,000,000 requests, every project returns a 429 page
saying the limit is reached, and deploys fail with `402 usage_limit`. Requests served
before the check can take usage a little past the cap. Projects come back on their own
when the next billing period starts.

If the subscription lapses, every route on the project —
including ones a static asset used to serve — starts returning a 402 placeholder page
until it's resumed; nothing is deleted, and the project's own content serves again as
soon as billing is current. See your usage any time in the dashboard under Settings, or with `giolt usage`.
