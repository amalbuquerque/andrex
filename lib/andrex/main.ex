defmodule Andrex.Main do
  @moduledoc """
  Functions that enable the so-called "main" pages.
  """

  alias Andrex.Utils
  alias Andrex.Blog.{Cache, Entry}
  require Logger

  @all_pages_key :all_pages
  @hide_from_navbar_option "hidefromnavbar"

  def get_navbar_pages(opts \\ [force_refresh: false]) do
    opts
    |> get_all_main_pages()
    |> Enum.reject(fn %Entry{andrex: andrex_opts} ->
      andrex_opts[@hide_from_navbar_option]
    end)
  end

  def get_all_main_pages(opts \\ [force_refresh: false]) do
    force_refresh? = Keyword.get(opts, :force_refresh)

    case {Cache.get(@all_pages_key), force_refresh?} do
      {nil, _} ->
        fresh_pages = refresh_cache()
        Logger.debug("No pages were cached. Fetched and cached #{Enum.count(fresh_pages)} pages: #{inspect(fresh_pages)}")

        fresh_pages

      {_pages, _force_refresh = true} ->
        fresh_pages = refresh_cache()
        Logger.debug("Force fetched #{Enum.count(fresh_pages)} pages: #{inspect(fresh_pages)}")

        fresh_pages

      {pages, _force_refresh = false} ->
        Logger.debug("Found #{Enum.count(pages)} cached pages: #{inspect(pages)}")

        pages
    end
  end

  def get_page(page) do
    Logger.debug("Main.get_page/1 trying to find: #{inspect(page)}")

    with {:ok, page_filename} <- page_filename(page),
         %Entry{} = page_entry <- Cache.get(page_filename)
    do
      {:ok, page_entry}
    else
      nil ->
        {:error, :not_found}

      {:error, _reason} = error ->
        Logger.error("Unexpected error while trying to find post: #{inspect(error)}")

        error
    end
  end

  def refresh_cache do
    fresh_pages = get_main_pages_from_filesystem()
                  |> Enum.sort_by(&(&1.filename), :desc)

    Logger.debug("Fetched #{Enum.count(fresh_pages)} pages from filesystem: #{inspect(fresh_pages)}")

    true = Cache.insert(@all_pages_key, fresh_pages)

    Enum.each(fresh_pages, &Cache.insert(&1.filename, &1))

    fresh_pages
  end

  def main_pages_list do
    main_pages_dir()
    |> File.ls!()
    |> Enum.map(&String.replace_suffix(&1, ".md", ""))
  end

  def get_main_pages_from_filesystem do
    main_pages_dir = main_pages_dir()

    main_pages_dir
    |> File.ls!()
    # TODO: Parallelize this
    |> Enum.map(fn page_filename ->
      raw_markdown =
        main_pages_dir
        |> Path.join(page_filename)
        |> File.read!()

        {:ok, page_entry} = Entry.from_markdown_without_date(page_filename, raw_markdown)

        page_entry
    end)
  end

  defp page_filename(page_filename) when is_binary(page_filename) do
    {:ok, "#{page_filename}.md"}
  end

  defp main_pages_dir do
    {:ok, path} = Utils.content_full_path("main")

    path
  end
end
