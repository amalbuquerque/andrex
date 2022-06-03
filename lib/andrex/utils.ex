defmodule Andrex.Utils do
  @app :andrex

  def maybe_found(result) when is_nil(result) or result == false, do: {:error, :not_found}

  def maybe_found(result), do: {:ok, result}

  def content_full_path(folder) do
    with prefix = content_dir_prefix(),
         full_path = Path.join(prefix, folder),
         true <- File.exists?(full_path) do
      {:ok, full_path}
    else
      _ ->
        {:error, :invalid_content_folder}
    end
  end

  defp content_dir_prefix do
    case content_root_path() do
      "priv/" <> remaining_path ->
        :code.priv_dir(@app)
        |> Path.join(remaining_path)
      full_path ->
        full_path
    end
  end

  defp content_root_path,
    do: Application.get_env(:andrex, :paths)[:content_root_folder]
end
