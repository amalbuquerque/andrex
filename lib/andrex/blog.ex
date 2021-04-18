defmodule Andrex.Blog do
  require Logger
  alias Andrex.Utils, as: U
  alias Andrex.Blog.{Pandoc, Cache}

  @app :andrex
  @priv_posts_path 'markdown'

  @all_posts_key :all_posts

  def get_post(params) do
    Logger.debug("Blog.get_post/1 trying to find: #{inspect(params)}")

    with {:ok, post_title} <- post_title(params),
         all_posts = get_all_posts() do
      Logger.debug("Blog.get_post/1 trying to find title: #{post_title}")

      all_posts
      |> Enum.find_value(fn
        {title, pandoc} when title == post_title ->
          Logger.debug("While trying to find #{post_title}, found #{inspect(pandoc)}")

          {:ok, pandoc.html}

        {_title, _pandoc} ->
          nil
      end)
      |> U.maybe_found()
    else
      error ->
        error
    end
  end

  def get_all_posts(opts \\ [raw: false, force_refresh: false]) do
    force_refresh? = Keyword.get(opts, :force_refresh)

    case {Cache.get(@all_posts_key), force_refresh?} do
      {nil, _} ->
        fresh_posts = get_posts_from_filesystem(opts)
        Logger.debug("Fetched #{Enum.count(fresh_posts)} posts from filesystem: #{inspect(fresh_posts)}")

        true = Cache.insert(@all_posts_key, fresh_posts)
        fresh_posts

      {posts, _force_refresh = false} ->
        Logger.debug("Found #{Enum.count(posts)} cached posts: #{inspect(posts)}")
        posts

      {_posts, _force_refresh = true} ->
        fresh_posts = get_posts_from_filesystem(opts)
        Logger.debug("Force fetched #{Enum.count(fresh_posts)} posts: #{inspect(fresh_posts)}")

        true = Cache.insert(@all_posts_key, fresh_posts)
        fresh_posts
    end
  end

  def get_posts_from_filesystem(opts \\ [raw: false]) do
    posts_dir = posts_dir()

    posts_dir
    |> File.ls!()
    # TODO: Parallelize this
    |> Enum.map(fn post ->
      raw_markdown =
        posts_dir
        |> Path.join(post)
        |> File.read!()

      case Keyword.get(opts, :raw) do
        true ->
          {post, raw_markdown}
        _ ->
          {:ok, pandoc} = Pandoc.from_markdown(raw_markdown)
          {post, pandoc}
      end
    end)
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
