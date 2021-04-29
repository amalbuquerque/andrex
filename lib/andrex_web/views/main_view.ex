defmodule AndrexWeb.MainView do
  use AndrexWeb, :view

  def render("main.html", %{page: page}) do
    # reusing the raw.html view
    Phoenix.View.render(AndrexWeb.BlogView, "raw.html", raw: page)
  end
end
