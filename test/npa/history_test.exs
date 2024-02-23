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

    test "adds to the front of history" do
      hist =
        History.new()
        |> History.record("łódź", "")
        |> History.record("koń", "")

      assert hist == ["koń", "łódź"]
    end

    test "phrase that was previously seen" do
      hist =
        ["Hello"]
        |> History.record("Hel", "")

      assert hist == ["Hello"]
    end
  end

  describe "restoring" do
    test "on empty history simply returns it" do
      hist =
        History.new()
        |> History.restore(~w"Hello World")

      assert hist == ~w"Hello World"
    end

    test "adds to the end of current history" do
      hist =
        History.new()
        |> History.record("Welcome", "")
        |> History.restore(~w"Hello World")

      assert hist == ~w"Welcome Hello World"
    end

    test "keeps history dupe-free and limited" do
      hist =
        History.new()
        |> History.record("Welcome", "")
        |> History.record("Hello", "")
        |> History.restore(~w"Hello World")

      assert hist == ~w"Hello Welcome World"
    end
  end
end
