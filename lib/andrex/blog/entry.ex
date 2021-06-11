defmodule Andrex.Blog.Entry do
  alias Andrex.Blog.Pandoc

  defstruct [:tags, :year, :month, :day, :url_title, :filename, :pandoc, :andrex]

  def from_markdown(filename, markdown) when is_binary(filename) and is_binary(markdown) do
    with {:ok, %Pandoc{metadata: metadata} = pandoc} <- Pandoc.from_markdown(markdown),
         {:ok, [year, month, day]} <- yyyy_mm_dd_from_filename(filename),
         {:ok, url_title} <- url_title(filename) do

      result = %__MODULE__{
        tags: tags_from_metadata(metadata),
        year: year,
        month: month,
        day: day,
        filename: filename,
        url_title: url_title,
        pandoc: pandoc,
        andrex: metadata[:andrex] || %{}
      }

      {:ok, result}
    else
      error -> error
    end
  end

  def from_markdown_without_date(filename, markdown) when is_binary(filename) and is_binary(markdown) do
    with {:ok, %Pandoc{metadata: metadata} = pandoc} <- Pandoc.from_markdown(markdown),
         url_title = String.replace_suffix(filename, ".md", "") do

      result = %__MODULE__{
        tags: tags_from_metadata(metadata),
        filename: filename,
        url_title: url_title,
        pandoc: pandoc,
        andrex: metadata[:andrex] || %{}
      }

      {:ok, result}
    else
      error -> error
    end
  end

  defp yyyy_mm_dd_from_filename(filename) do
    filename
    |> String.split("-")
    |> case do
      [yyyy, mm, dd, _url_title_hd | _url_title_rest] when byte_size(yyyy) == 4 and byte_size(mm) == 2 and byte_size(dd) == 2 ->
        {:ok, [yyyy, mm, dd]}
      _ ->
        {:error, :unexpected_filename_format}
    end
  end

  def url_title(filename) do
    filename
    |> String.split("-")
    |> case do
      [yyyy, mm, dd, url_title_hd | url_title_rest] when byte_size(yyyy) == 4 and byte_size(mm) == 2 and byte_size(dd) == 2 ->
        url_title = [url_title_hd | url_title_rest]
                    |> Enum.join("-")
                    |> String.replace_suffix(".md", "")
        {:ok, url_title}
      _ ->
        {:error, :unexpected_filename_format}
    end
  end

  defp tags_from_metadata(%{tags: raw_tags}) do
    raw_tags
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp tags_from_metadata(_), do: ["(no tags)"]
end
