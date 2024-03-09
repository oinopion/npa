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

    test "ignores white space" do
      assert ["Alfa", "Bravo", "Charlie"] = Transcriber.transcribe("A  B\n  C")
    end
  end

  describe "transcrive_phrase" do
    test "returns empty list on empty input" do
      assert [] == Transcriber.transcribe_phrase("")
    end

    test "returns pairs or word -> list of codewords" do
      result = Transcriber.transcribe_phrase("Hello World")

      assert [
               {"Hello", Transcriber.transcribe("Hello")},
               {"World", Transcriber.transcribe("World")}
             ] == result
    end

    test "normalises white space to a signle space character" do
      result = Transcriber.transcribe_phrase("A  B\n  C   ")

      assert [{"A", ["Alfa"]}, {"B", ["Bravo"]}, {"C", ["Charlie"]}] == result
    end
  end
end
