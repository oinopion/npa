defmodule DebouncerTest do
  use ExUnit.Case, async: true

  @debounce_ms 10

  setup do
    {:ok, debouncer} = Debouncer.start_link(@debounce_ms)
    %{debouncer: debouncer}
  end

  test "message is received only after debounce period", %{debouncer: debouncer} do
    Debouncer.schedule(debouncer, :test_message)

    # Not received immediately
    refute_received(:test_message)

    # Not received after half the debounce period
    Process.sleep(div(@debounce_ms, 2))
    refute_received(:test_message)

    # Received after the full period
    Process.sleep(div(@debounce_ms, 2))
    assert_received(:test_message)
  end

  test "calling twice in a row leads to only one message", %{debouncer: debouncer} do
    Debouncer.schedule(debouncer, :test_message)
    Debouncer.schedule(debouncer, :test_message)

    Process.sleep(@debounce_ms)
    assert_received(:test_message)
    refute_received(:test_message)
  end

  test "calling after first fire schedules next message", %{debouncer: debouncer} do
    Debouncer.schedule(debouncer, :test_message)

    # Wait for first message
    Process.sleep(@debounce_ms)
    assert_received(:test_message)

    Debouncer.schedule(debouncer, :test_message)

    # Wait for second message
    Process.sleep(@debounce_ms)
    assert_received(:test_message)
  end

  test "cancelling prevents sending message", %{debouncer: debouncer} do
    Debouncer.schedule(debouncer, :test_message)
    Debouncer.cancel(debouncer)

    Process.sleep(@debounce_ms)
    refute_receive(:test_message, @debounce_ms)
  end

  test "cancelling twice is fine", %{debouncer: debouncer} do
    Debouncer.schedule(debouncer, :test_message)
    Debouncer.cancel(debouncer)
    assert :ok == Debouncer.cancel(debouncer)
  end

  test "cancelling after receive is fine", %{debouncer: debouncer} do
    Debouncer.schedule(debouncer, :test_message)
    Process.sleep(@debounce_ms)
    assert_received(:test_message)

    assert :ok == Debouncer.cancel(debouncer)
  end
end
