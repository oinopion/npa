defmodule Npa.History do
  @type t :: list()

  @spec new() :: __MODULE__.t()
  def new() do
    []
  end

  @spec record(__MODULE__.t(), binary(), binary()) :: __MODULE__.t()
  def record(history, previous, current) when is_list(history) do
    cond do
      # previous == "" ->
      # Never add empty string to history
      # history

      String.starts_with?(current, previous) ->
        # Continuing to add to current phrase, do nothing
        history

      Enum.any?(history, fn item -> String.starts_with?(item, previous) end) ->
        # There's already an entry like this, do nothing
        history

      true ->
        [previous | history]
    end
  end
end
