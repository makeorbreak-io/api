defmodule ApiWeb.StringHelperTest do
  use ExUnit.Case, async: true

  alias ApiWeb.StringHelper

  test "slugify" do
    assert StringHelper.slugify("*** Cenas R4nd (@#$@%^") == "cenas-r4nd"
  end
end
