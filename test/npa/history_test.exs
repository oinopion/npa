defmodule Npa.HistoryTest do
  use ExUnit.Case, async: true

  alias Npa.History

  test "new/0 returns an empty list" do
    assert History.new() == []
  end

  describe "recording" do
    test "adding empty string is not saved" do
      hist =
        History.new()
        |> History.record("", "H")

      assert hist == []
    end

    test "adding letters to a phrase has no effect" do
      hist =
        History.new()
        |> History.record("ł", "łó")

      assert hist == []
    end

    test "changing phrase completely records previous one" do
      hist =
        History.new()
        |> History.record("łódź", "koń")

      assert hist == ["łódź"]
    end

    test "phrase that was previously seen" do
      hist =
        ["Hello"]
        |> History.record("Hel", "")

      assert hist == ["Hello"]
    end
  end
end
