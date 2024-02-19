defmodule NPAWeb.TranscribeLiveTest do
  alias NPA.Transcriber
  use NPAWeb.ConnCase

  import Phoenix.LiveViewTest

  test "starts with no text", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/")

    assert extract_transcription(html) == []
  end

  test "uses query params for initial test", %{conn: conn} do
    initial_text = "Hello"

    {:ok, _live, html} = live(conn, ~p"/?#{[text: initial_text]}")

    assert extract_transcription(html) == Transcriber.transcribe(initial_text)
  end

  test "trims initial long texts to 100 characters", %{conn: conn} do
    long_text = String.duplicate("Ł", 101)

    {:ok, _live, html} = live(conn, ~p"/?#{[text: long_text]}")

    transcription = extract_transcription(html)
    assert length(transcription) == 100
    assert String.starts_with?(long_text, Enum.into(transcription, ""))
  end

  test "updates transcription on change", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    new_code_words =
      live
      |> element("input")
      |> render_change(%{text: "Hello"})
      |> extract_transcription()

    assert new_code_words == Transcriber.transcribe("Hello")
  end

  test "trims new text to 100 characters", %{conn: conn} do
    long_text = String.duplicate("Ł", 101)
    {:ok, live, _html} = live(conn, ~p"/")

    transcription =
      live
      |> element("input")
      |> render_change(%{text: long_text})
      |> extract_transcription()

    assert length(transcription) == 100
    assert String.starts_with?(long_text, Enum.into(transcription, ""))
  end

  test "keeps history", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    live
    |> element("input")
    |> render_change(%{text: "Hello"})

    history =
      live
      |> element("input")
      |> render_change(%{text: "Hi"})
      |> extract_history()

    assert history == ["Hello"]
  end

  defp extract_transcription(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find("#transcription span")
    |> Enum.map(&Floki.text(&1, sep: " "))
  end

  defp extract_history(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find("#history li")
    |> Enum.map(&Floki.text(&1, sep: " "))
  end
end
