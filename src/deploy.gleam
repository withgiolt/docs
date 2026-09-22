//// Ships the built site to Giolt. Run with `just deploy`.

import build
import envie
import giolt_sdk/deploy
import gleam/javascript/promise.{type Promise}

const token_var = "GIOLT_TOKEN"

/// The SDK defaults to `https://giolt.com`, but `/api/deploy` is served by
/// the dash worker. `GIOLT_API_URL` still wins over this — the SDK reads it
/// itself and takes it in preference to whatever is set here.
const api_url = "https://dash.giolt.com"

pub fn main() -> Promise(Nil) {
  let _ = envie.load()

  let output = build.main()

  deploy.new()
  |> deploy.from(output)
  |> deploy.token_from_env(token_var)
  |> deploy.api_url(api_url)
  |> deploy.run
  |> promise.map(fn(result) {
    deploy.print_result(result)

    // `deploy.run` has already printed what went wrong; this is only here so
    // a failed deploy exits non-zero instead of leaving CI green.
    let assert Ok(_) = result as "Deployment failed"

    Nil
  })
}
