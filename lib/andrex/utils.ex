defmodule Andrex.Utils do
  def maybe_found(result) when is_nil(result) or result == false, do: {:error, :not_found}

  def maybe_found(result), do: result
end
