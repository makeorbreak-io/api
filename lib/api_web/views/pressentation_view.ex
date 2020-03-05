defmodule ApiWeb.PresentationView do
  use ApiWeb, :view

  def render("posts.json", %{posts: posts}) do
    %{data: posts}
  end
end
