defmodule ApiWeb.Crypto do
  def hmac(key, text) do
    Base.encode16(:crypto.hmac(:sha256, key, text))
  end

  def random_hmac do
    hmac(
      to_string(:rand.uniform()),
      to_string(DateTime.to_unix(DateTime.utc_now()))
    )
  end
end
