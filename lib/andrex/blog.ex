defmodule Andrex.Blog do
  require Logger
  alias Andrex.Blog.{Pandoc, Cache}

  @app :andrex
  @priv_posts_path 'markdown'

  @all_posts_key :all_posts
  @all_tags_key :all_tags
  @titles_per_tag_key :titles_per_tag

  def get_post(params) do
    Logger.debug("Blog.get_post/1 trying to find: #{inspect(params)}")

    with {:ok, post_title} <- post_title(params),
         Logger.debug("Blog.get_post/1 trying to find title: #{post_title}"),
         %Pandoc{} = pandoc <- Cache.get(post_title)
    do
      {:ok, pandoc}
    else
      nil ->
        {:error, :not_found}

      error ->
        Logger.error("Unexpected error while trying to find post: #{inspect(error)}")

        {:error, error}
    end
  end

  def get_all_posts(opts \\ [force_refresh: false]) do
    force_refresh? = Keyword.get(opts, :force_refresh)

    case {Cache.get(@all_posts_key), force_refresh?} do
      {nil, _} ->
        {fresh_posts, _titles_per_tag} = refresh_cache()
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

  @doc """
  Fetches the posts from the filesystem and:
    - Caches all posts
    - Caches each post using its title as the cache key
    - Caches all tags
    - Caches the list of post titles per tag
  """
  def refresh_cache do
    fresh_posts = get_posts_from_filesystem()
    Logger.debug("Fetched #{Enum.count(fresh_posts)} posts from filesystem: #{inspect(fresh_posts)}")

    true = Cache.insert(@all_posts_key, fresh_posts)

    tags = fresh_posts
           |> Enum.reduce(%{}, fn {title, %Pandoc{metadata: metadata} = post}, acc ->
             true = Cache.insert(title, post)

             tags = tags_from_metadata(metadata)

             tags
             |> Enum.reduce(acc, fn tag, titles_per_tag ->
               titles_per_tag
               |> Map.update(tag,[title],
                 fn existing_titles -> [title | existing_titles] end)
             end)
           end)

    true = Cache.insert(@titles_per_tag_key, tags)

    all_tags = Map.keys(tags)
    true = Cache.insert(@all_tags_key, all_tags)

    {fresh_posts, tags}
  end

  defp tags_from_metadata(%{tags: raw_tags}) do
    raw_tags
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp tags_from_metadata(_), do: ["(no tags)"]

  defp posts_dir do
    :code.priv_dir(@app)
    |> Path.join(@priv_posts_path)
  end

  defp post_title(%{"day" => day, "month" => month, "title" => title, "year" => year}) do
    {:ok, "#{year}-#{month}-#{day}-#{title}.md"}
  end

  defp post_title(_), do: {:error, :invalid_title_params}
end
