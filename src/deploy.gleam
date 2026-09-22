//// Ships the built site to Giolt. Run with `just deploy`.

import build
import envie
import giolt_sdk/deploy
import gleam/javascript/promise.{type Promise}

const token_var = "GIOLT_TOKEN"

const project_id_var = "GIOLT_PROJECT_ID"

const api_url_var = "GIOLT_API_URL"

/// The deploy endpoint lives on the dash worker, not on giolt.com — that is
/// where the routes authenticated by a project's deploy key are served.
const default_api_url = "https://dash.giolt.com"

pub fn main() -> Promise(Nil) {
  let _ = envie.load()

  let output = build.main()

  deploy.new()
  |> deploy.project_id(envie.get_string(project_id_var, ""))
  |> deploy.from(output)
  |> deploy.token_from_env(token_var)
  |> deploy.api_url(envie.get_string(api_url_var, default_api_url))
  |> deploy.run
  |> promise.map(fn(result) {
    deploy.print_result(result)

    // `deploy.run` has already printed what went wrong; this is only here so
    // a failed deploy exits non-zero instead of leaving CI green.
    let assert Ok(_) = result as "Deployment failed"

    Nil
  })
}
