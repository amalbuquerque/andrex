defmodule AndrexWeb.BlogController do
  require Logger
  alias Andrex.Blog

  use AndrexWeb, :controller

  action_fallback AndrexWeb.FallbackController

  def index(conn, _params) do
    render(conn, "blog.html")
  end

  def entry(conn, params) do
    Logger.debug("Blog entry requested. Params: #{inspect(params)}")

    with {:ok, post} <- Blog.get_post(params) do
      render(conn, "entry.html", post: post)
    end
  end
end
