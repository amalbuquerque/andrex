defmodule AndrexWeb.PageView do
  use AndrexWeb, :view

  def render("home.html", %{page: page}) do
    # reusing the raw.html view
    Phoenix.View.render(AndrexWeb.BlogView, "raw.html", raw: page)
  end
end
