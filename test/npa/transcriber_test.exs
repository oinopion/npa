defmodule NPA.TranscriberTest do
  use ExUnit.Case, async: true

  alias NPA.Transcriber

  describe "transcribe/1" do
    test "returns empty list on empty input" do
      assert [] = Transcriber.transcribe("")
    end

    test "returns list of code words on a single word" do
      assert ~w(Tango Oscar Mike Echo Kilo) = Transcriber.transcribe("Tomek")
    end

    test "returns divides multiple words with a space" do
      assert ["Xray", " ", "Yankee"] = Transcriber.transcribe("X Y")
    end

    test "normalises white space to a signle space character" do
      assert ["Alfa", " ", "Bravo", " ", "Charlie"] = Transcriber.transcribe("A  B\n  C")
    end
  end
end
