defmodule NPA.Transcriber do
  # See: https://en.wikipedia.org/wiki/NATO_phonetic_alphabet
  @code_words %{
    "A" => "Alfa",
    "B" => "Bravo",
    "C" => "Charlie",
    "D" => "Delta",
    "E" => "Echo",
    "F" => "Foxtrot",
    "G" => "Golf",
    "H" => "Hotel",
    "I" => "India",
    "J" => "Juliett",
    "K" => "Kilo",
    "L" => "Lima",
    "M" => "Mike",
    "N" => "November",
    "O" => "Oscar",
    "P" => "Papa",
    "Q" => "Quebec",
    "R" => "Romeo",
    "S" => "Sierra",
    "T" => "Tango",
    "U" => "Uniform",
    "V" => "Victor",
    "W" => "Whiskey",
    "X" => "Xray",
    "Y" => "Yankee",
    "Z" => "Zulu"
  }

  @doc """
  Returns a list of pairs of letters from the given phrase and it's NATO code word.

  White spaces are normalised to a single space. Letters from outside the Roman alphabet are mapped
  to `nil`.
  """
  def transcribe(phrase) do
    Regex.replace(~r/\s+/, phrase, " ")
    |> String.upcase()
    |> String.codepoints()
    |> Enum.map(&code_word/1)
  end

  defp code_word(codepoint) do
    Map.get(@code_words, codepoint, codepoint)
  end
end
