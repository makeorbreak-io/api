defmodule Api.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :api,
    error_handler: Api.GuardianErrorHandler,
    module: Api.Guardian

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
end
