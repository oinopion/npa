defmodule Debouncer do
  use GenServer

  @default_key :__debouncer_default_key

  # Client interface

  def start_link(debounce_ms) do
    client_pid = self()
    GenServer.start_link(__MODULE__, {debounce_ms, client_pid})
  end

  def schedule(pid, key \\ @default_key, message) do
    GenServer.call(pid, {:schedule, key, message})
  end

  def cancel(pid, key \\ @default_key) do
    GenServer.call(pid, {:cancel, key})
  end

  # Server callback implementations

  @impl true
  def init({debounce_ms, client_pid}) when is_integer(debounce_ms) and is_pid(client_pid) do
    {:ok, %{debounce_ms: debounce_ms, client_pid: client_pid, timers: %{}}}
  end

  @impl true
  def handle_call(
        {:schedule, key, message},
        _from,
        %{
          debounce_ms: debounce_ms,
          client_pid: client_pid,
          timers: timers
        } = state
      ) do
    if should_schedule?(timers[key]) do
      timer = Process.send_after(client_pid, message, debounce_ms)
      # timer = Process.send_after(client_pid, message, debounce_ms)
      {:reply, :ok, %{state | timers: Map.put(timers, key, timer)}}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call({:cancel, key}, _from, %{timers: timers} = state) do
    case Map.pop(timers, key) do
      {nil, _timers} ->
        {:reply, :ok, state}

      {timer, new_timers} ->
        Process.cancel_timer(timer)
        {:reply, :ok, %{state | timers: new_timers}}
    end
  end

  defp should_schedule?(nil = _timer), do: true

  defp should_schedule?(timer) when is_reference(timer) do
    Process.read_timer(timer) == false
  end
end
