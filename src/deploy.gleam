import build
import envie
import giolt_sdk/deploy
import gleam/javascript/promise.{type Promise}

const token_var = "GIOLT_TOKEN"

const api_url = "https://dash.giolt.com"

pub fn main() -> Promise(Nil) {
  let _ = envie.load()
  let _ = build.main()

  deploy.new()
  |> deploy.token_from_env(token_var)
  |> deploy.artifact("./dist")
  |> deploy.api_url(api_url)
  |> deploy.run
  |> promise.map(fn(result) {
    deploy.print_result(result)
    let assert Ok(_) = result as "Deployment failed"
    Nil
  })
}
