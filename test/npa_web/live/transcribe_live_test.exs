defmodule NPAWeb.TranscribeLiveTest do
  alias NPA.Transcriber
  use NPAWeb.ConnCase

  import Phoenix.LiveViewTest

  test "starts with default text", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/")

    assert extract_transcription(html) == Transcriber.transcribe("Tomek")
  end

  test "updates transcription on change", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    new_code_words =
      live
      |> element("input")
      |> render_change(%{text: "WTF"})
      |> extract_transcription()

    assert new_code_words == Transcriber.transcribe("WTF")
  end

  defp extract_transcription(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find("#transcription span")
    |> Enum.map(&Floki.text(&1, sep: " "))
  end
end
