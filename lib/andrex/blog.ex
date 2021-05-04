defmodule Andrex.Blog do
  require Logger
  alias Andrex.Utils
  alias Andrex.Blog.{Cache, Entry}

  @app :andrex
  @priv_blog_posts_path 'markdown/blog'

  @all_posts_key :all_posts
  @all_tags_key :all_tags
  @filenames_per_tag_key :filenames_per_tag

  def filenames_per_tag do
    # get all tags
    @filenames_per_tag_key
    |> Cache.get()
    |> Utils.maybe_found()
  end

  def filenames_with_tag(tag) do
    @filenames_per_tag_key
    |> Cache.get()
    |> Map.get(tag)
    |> Utils.maybe_found()
  end

  def get_post!(params_or_filename) do
    case get_post(params_or_filename) do
      {:ok, post} ->
        post
      error ->
        error
    end
  end

  def get_post(params_or_filename) do
    Logger.debug("Blog.get_post/1 trying to find: #{inspect(params_or_filename)}")

    with {:ok, post_filename} <- post_filename(params_or_filename),
         %Entry{} = blog_entry <- Cache.get(post_filename)
    do
      {:ok, blog_entry}
    else
      nil ->
        {:error, :not_found}

      {:error, _reason} = error ->
        Logger.error("Unexpected error while trying to find post: #{inspect(error)}")

        error
    end
  end

  def get_all_posts(opts \\ [force_refresh: false]) do
    force_refresh? = Keyword.get(opts, :force_refresh)

    case {Cache.get(@all_posts_key), force_refresh?} do
      {nil, _} ->
        {fresh_posts, _filenames_per_tag} = refresh_cache()
        Logger.debug("No posts were cached. Fetched and cached #{Enum.count(fresh_posts)} posts: #{inspect(fresh_posts)}")

        fresh_posts

      {_posts, _force_refresh = true} ->
        {fresh_posts, _filenames_per_tag} = refresh_cache()
        Logger.debug("Refreshed #{Enum.count(fresh_posts)} posts: #{inspect(fresh_posts)}")

        fresh_posts

      {posts, _force_refresh = false} ->
        Logger.debug("Found #{Enum.count(posts)} cached posts: #{inspect(posts)}")

        posts
    end
  end

  def get_posts_from_filesystem(opts \\ [raw: false]) do
    posts_dir = posts_dir()

    posts_dir
    |> File.ls!()
    # TODO: Parallelize this
    |> Enum.map(fn post_filename ->
      raw_markdown =
        posts_dir
        |> Path.join(post_filename)
        |> File.read!()

      case Keyword.get(opts, :raw) do
        true ->
          raw_markdown
        _ ->
          {:ok, blog_entry} = Entry.from_markdown(post_filename, raw_markdown)
          blog_entry
      end
    end)
  end

  @doc """
  Fetches the posts from the filesystem and:
    - Caches all posts
    - Caches each post using its filename as the cache key
    - Caches all tags
    - Caches the list of post filenames per tag
  """
  def refresh_cache do
    fresh_posts = get_posts_from_filesystem()
                  |> Enum.sort_by(&(&1.filename), :desc)

    Logger.debug("Fetched #{Enum.count(fresh_posts)} posts from filesystem: #{inspect(fresh_posts)}")

    true = Cache.insert(@all_posts_key, fresh_posts)

    tags = fresh_posts
           |> Enum.reduce(%{}, fn %Entry{tags: tags, filename: filename} = post, acc ->
             true = Cache.insert(filename, post)

             tags
             |> Enum.reduce(acc, fn tag, filenames_per_tag ->
               filenames_per_tag
               |> Map.update(tag,[filename],
                 fn existing_filenames -> [filename | existing_filenames] end)
             end)
           end)

    true = Cache.insert(@filenames_per_tag_key, tags)

    all_tags = Map.keys(tags)
    true = Cache.insert(@all_tags_key, all_tags)

    {fresh_posts, tags}
  end

  defp posts_dir do
    :code.priv_dir(@app)
    |> Path.join(@priv_blog_posts_path)
  end

  defp post_filename(post_filename) when is_binary(post_filename) do
    {:ok, post_filename}
  end

  defp post_filename(%{"day" => day, "month" => month, "title" => title, "year" => year}) do
    {:ok, "#{year}-#{month}-#{day}-#{title}.md"}
  end

  defp post_filename(_), do: {:error, :invalid_filename_params}
end
