defmodule Andrex.Blog do
  require Logger

  @app :andrex
  @priv_posts_path 'markdown'

  def get_all_posts do
    posts_dir = posts_dir()

    posts_dir
    |> File.ls!()
    |> Enum.map(fn post -> # TODO: Parallelize this
      markdown = posts_dir
                 |> Path.join(post)
                 |> File.read!()

      html = html_from_markdown(markdown)

      {post, html}
    end)
  end

  defp html_from_markdown(markdown) when is_binary(markdown) do
    Panpipe.pandoc(markdown, to: :html)
    |> case do
      {:ok, html} -> html
      _ ->
        Logger.warn("Problem converting the following markdown to HTML:\n#{markdown}")

        "Problem converting markdown: #{String.slice(markdown, 0..30)}"
    end
  end

  defp posts_dir do
    :code.priv_dir(@app)
    |> Path.join(@priv_posts_path)
  end
end
