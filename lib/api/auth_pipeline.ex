defmodule Api.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :api,
    error_handler: ApiWeb.GuardianErrorHandler,
    module: ApiWeb.Guardian

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
end
