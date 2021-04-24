defmodule Andrex.Blog.Pandoc do
  require Logger

  @pandoc_from_rule {:markdown_mmd, [:emoji]}
  @pandoc_to_rule {:html, %{enable: [:mmd_title_block]}}

  defstruct [:metadata, :raw_markdown, :html, :filename]

  def from_markdown(filename, markdown) when is_binary(markdown) do
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
        html: html,
        filename: filename
      }

      {:ok, result}
    end)
  end

  defp metadata_from_markdown(markdown) do
    {:ok, %Panpipe.Document{meta: metadata}} = pandoc_ast_from_markdown(markdown)

    Logger.debug(
      "#{inspect(String.slice(markdown, 0..100))} produced the following Pandoc AST meta:\n#{inspect(metadata)}"
    )

    metadata
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      key = String.to_atom(key)
      parsed_value = parse_pandoc_ast_value(value)

      Map.put(acc, key, parsed_value)
    end)
  end

  defp parse_pandoc_ast_value(%{"c" => [%{"c" => split_value}]}) do
    Enum.reduce(split_value, [], fn
      %{"t" => "Str", "c" => v}, acc ->
        [v | acc]

      _, acc ->
        acc
    end)
    |> Enum.reverse()
    |> Enum.join(" ")
  end

  defp pandoc_ast_from_markdown(markdown),
    do: Panpipe.ast(markdown, from: @pandoc_from_rule)
end
