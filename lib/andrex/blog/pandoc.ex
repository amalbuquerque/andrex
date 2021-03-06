defmodule Andrex.Blog.Pandoc do
  require Logger

  @pandoc_from_rule {:markdown_mmd, [:emoji]}
  @pandoc_to_rule {:html, %{enable: [:mmd_title_block]}}

  defstruct [:metadata, :raw_markdown, :html, :filename]

  def from_markdown(markdown) when is_binary(markdown) do
    metadata = metadata_from_markdown(markdown)

    Panpipe.pandoc(markdown,
      from: @pandoc_from_rule,
      to: @pandoc_to_rule
    )
    |> case do
      {:ok, html} ->
        html

      error ->
        Logger.warn(
          "Error #{inspect(error)} converting the following markdown to HTML:\n#{markdown}"
        )

        "Problem converting markdown: #{String.slice(markdown, 0..30)}"
    end
    |> then(fn html ->
      result = %__MODULE__{
        metadata: metadata,
        raw_markdown: markdown,
        html: html
      }

      {:ok, result}
    end)
  end

  defp metadata_from_markdown(markdown) do
    {:ok, %Panpipe.Document{meta: metadata}} = pandoc_ast_from_markdown(markdown)

    Logger.debug(
      "#{inspect(String.slice(markdown, 0..100))} produced the following Pandoc AST meta:\n#{inspect(metadata)}"
    )

    aggregate_metadata(metadata)
  end

  defp aggregate_metadata(metadata) do
    metadata
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      parsed_value = parse_pandoc_ast_value(value)

      {key_to_store, value_to_store} = case key do
        "andrex-" <> andrex_key ->
          andrex_metadata = acc[:andrex] || %{}
          andrex_metadata = Map.put(andrex_metadata, andrex_key, parsed_value)

          {:andrex, andrex_metadata}

        metadata_key ->
          {String.to_atom(metadata_key), parsed_value}
      end

      Map.put(acc, key_to_store, value_to_store)
    end)
  end

  defp parse_pandoc_ast_value(%{"c" => [%{"c" => split_value}]}) do
    v = Enum.reduce(split_value, [], fn
      %{"t" => "Str", "c" => v}, acc ->
        [v | acc]

      _, acc ->
        acc
    end)
    |> Enum.reverse()
    |> Enum.join(" ")

    cond do
      v in ["True", "true", "T"] -> true
      v in ["False", "false", "F"] -> false
      v -> v
    end
  end

  defp pandoc_ast_from_markdown(markdown),
    do: Panpipe.ast(markdown, from: @pandoc_from_rule)
end
