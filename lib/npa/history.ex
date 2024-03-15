defmodule NPA.History do
  @type t :: list(binary())

  @history_limit 5

  @spec new() :: __MODULE__.t()
  def new() do
    []
  end

  @spec record(__MODULE__.t(), binary(), binary()) :: __MODULE__.t()
  def record(history, previous, current) when is_list(history) do
    cond do
      previous == "" ->
        # Never add empty string to history
        history

      String.starts_with?(current, previous) ->
        # Continuing to add to current phrase, do nothing
        history

      Enum.any?(history, fn item -> String.starts_with?(item, previous) end) ->
        # There's already an entry like this, do nothing
        history

      true ->
        [previous | history] |> Enum.take(@history_limit)
    end
  end

  def restore(history, stored_entires) when is_list(history) and is_list(stored_entires) do
    history
    |> Enum.concat(stored_entires)
    |> Enum.uniq()
    |> Enum.take(@history_limit)
  end
end
