defmodule AndrexWeb.BlogController do
  require Logger
  alias Andrex.Blog

  use AndrexWeb, :controller

  action_fallback AndrexWeb.FallbackController

  def index(conn, _params) do
    with posts <- Blog.get_all_posts(),
         {:ok, filenames_per_tag} <- Blog.filenames_per_tag()
    do
      render(conn, "index.html", posts: posts, filenames_per_tag: filenames_per_tag)
    end
  end

  def tag(conn, %{"tag" => tag}) do
    with {:ok, titles} <- Blog.filenames_with_tag(tag),
         {:ok, filenames_per_tag} <- Blog.filenames_per_tag(),
         posts <- Enum.map(titles, &Blog.get_post!/1)
    do
      # TODO: Show a banner/title saying we're checking the posts for the given tag
      # and hide the tags section
      render(conn, "index.html", posts: posts, filenames_per_tag: filenames_per_tag)
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Tag not found.")
        |> redirect(to: Routes.blog_path(conn, :index))
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
