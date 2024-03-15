defmodule NPAWeb.TranscribeLiveTest do
  use NPAWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias NPA.Transcriber

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

  test "updates url params with new text on blur", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    live
    |> element("input")
    |> tap(&render_change(&1, %{text: "Hello"}))
    |> tap(&render_blur(&1))

    assert_patch(live, ~p"/?#{[text: "Hello"]}")
  end

  test "updates url params with new text on submit", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    live
    |> element("input")
    |> render_change(%{text: "Hello"})

    live
    |> element("form")
    |> render_submit()

    assert_patch(live, ~p"/?#{[text: "Hello"]}")
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

  test "clears history", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    # Add some history entires
    live
    |> element("input")
    |> tap(&render_change(&1, %{text: "Hello"}))
    |> tap(&render_change(&1, %{text: "World"}))

    history =
      live
      |> element("#history button")
      |> render_click()
      |> extract_history()

    assert history == []
  end

  test "restores history", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    history =
      live
      |> element("#form")
      |> render_hook("restore_history", %{"history" => Jason.encode!(~w"Hello World")})
      |> extract_history()

    assert history == ~w"Hello World"
  end

  test "pushes history to the browser", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    # Add some history entires
    live
    |> element("input")
    |> tap(&render_change(&1, %{text: "Hello"}))
    |> tap(&render_change(&1, %{text: "World"}))
    |> tap(&render_change(&1, %{text: ""}))

    send(live.pid, :store_history)

    assert_push_event(live, "store_history", %{"history" => history_json})
    assert Jason.decode!(history_json) == ~w"World Hello"
  end

  test "clears text", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/?#{[text: "Hello"]}")

    live
    |> element("#clear_text")
    |> render_click()

    text =
      live
      |> element("input")
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.attribute("value")

    assert text == [""]
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
