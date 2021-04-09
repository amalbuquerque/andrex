defmodule AndrexWeb.BlogView do
  use AndrexWeb, :view

  def render("entry.html", %{post: post}) do
    Phoenix.View.render(AndrexWeb.BlogView, "raw.html", raw: post)
  end
end
