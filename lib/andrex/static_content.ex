defmodule Andrex.StaticContent do
  alias Andrex.Utils

  @moduledoc """
  Module responsible for providing the static content from the blog content.
  """

  @static_contents_folder "static"

  @doc """
  Returns the file contents, along with the MIME type.
  """
  def get_static_content(path) do
    with relative_path = Path.join(@static_contents_folder, path),
         {:ok, content_full_path} <- Utils.content_full_path(relative_path),
         {:ok, contents} <- File.read(content_full_path) do
      {:ok, contents, MIME.from_path(path)}
    else
      {:error, :invalid_content_folder} ->
        {:error, :not_found}
      {:error, :enoent} ->
        {:error, :not_found}
      error ->
        error
    end
  end
end
