defmodule NPAWeb.TranscribeLive do
  use NPAWeb, :live_view

  @text_limit 100

  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(text_limit: @text_limit)
      |> assign_new_text(Map.get(params, "text", ""))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <form>
      <input
        phx-change="input_change"
        id="text"
        name="text"
        type="text"
        value={@text}
        placeholder="Phrase to spell out"
        maxlength={@text_limit}
        class="w-full rounded border-2 border-indigo-600"
      />
    </form>
    <div id="transcription">
      <%= for word <- @transcription do %>
        <span><%= word %></span>
      <% end %>
    </div>
    """
  end

  def handle_event("input_change", %{"text" => new_text}, socket) do
    {:noreply, assign_new_text(socket, new_text)}
  end

  defp assign_new_text(socket, new_text) do
    new_text =
      new_text
      |> String.slice(0, @text_limit)

    assign(socket, text: new_text, transcription: NPA.Transcriber.transcribe(new_text))
  end
end
