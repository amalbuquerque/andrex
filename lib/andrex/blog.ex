defmodule Andrex.Blog do
  require Logger
  alias Andrex.Utils, as: U

  @app :andrex
  @priv_posts_path 'markdown'

  def get_post(params) do
    Logger.debug("Blog.get_post/1 trying to find: #{inspect(params)}")

    with {:ok, post_title} <- post_title(params),
         all_posts = get_all_posts() do
      Logger.debug("Blog.get_post/1 trying to find: #{post_title}")

      all_posts
      |> Enum.find_value(fn
        {title, content} when title == post_title ->
          {:ok, content}

        {_title, _content} ->
          nil
      end)
      |> U.maybe_found()
    else
      error ->
        error
    end
  end

  def get_all_posts do
    posts_dir = posts_dir()

    posts_dir
    |> File.ls!()
    # TODO: Parallelize this
    |> Enum.map(fn post ->
      markdown =
        posts_dir
        |> Path.join(post)
        |> File.read!()

      html = html_from_markdown(markdown)

      {post, html}
    end)
  end

  defp html_from_markdown(markdown) when is_binary(markdown) do
    Panpipe.pandoc(markdown, to: :html)
    |> case do
      {:ok, html} ->
        html

      _ ->
        Logger.warn("Problem converting the following markdown to HTML:\n#{markdown}")

        "Problem converting markdown: #{String.slice(markdown, 0..30)}"
    end
  end

  defp posts_dir do
    :code.priv_dir(@app)
    |> Path.join(@priv_posts_path)
  end

  defp post_title(%{"day" => day, "month" => month, "title" => title, "year" => year}) do
    {:ok, "#{year}-#{month}-#{day}-#{title}.md"}
  end

  defp post_title(_), do: {:error, :invalid_title_params}
end
