defmodule AndrexWeb.BlogController do
  require Logger
  alias Andrex.Blog

  use AndrexWeb, :controller

  action_fallback AndrexWeb.FallbackController

  def index(conn, _params) do
    with posts <- Blog.get_all_posts() do
      render(conn, "index.html", posts: posts)
    end
  end

  def entry(conn, params) do
    Logger.debug("Blog entry requested. Params: #{inspect(params)}")

    with {:ok, %Blog.Entry{} = post} <- Blog.get_post(params) do
      render(conn, "entry.html", post: post.pandoc.html)
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Blog entry not found.")
        |> redirect(to: Routes.blog_path(conn, :index))
    end
  end
end
