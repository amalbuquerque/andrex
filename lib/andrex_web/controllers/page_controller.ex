defmodule AndrexWeb.PageController do
  use AndrexWeb, :controller

  alias Andrex.Blog

  def index(conn, _params) do
    {:ok, %Blog.Entry{} = page} = Andrex.Main.get_page("home")

    render(conn, "home.html", page: page.pandoc.html)
  end
end
