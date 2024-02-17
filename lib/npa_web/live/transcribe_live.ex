defmodule NPAWeb.TranscribeLive do
  use NPAWeb, :live_view

  def mount(_parms, _session, socket) do
    initial = "Tomek"
    socket = assign(socket, text: initial, transcription: NPA.Transcriber.transcribe(initial))
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <form onsubmit="return false;">
      <input
        phx-change="input_change"
        id="text"
        name="text"
        type="text"
        value={@text}
        placeholder="Phrase to spell out"
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

  def handle_event("input_change", %{"text" => new_value}, socket) do
    {:noreply,
     assign(socket, text: new_value, transcription: NPA.Transcriber.transcribe(new_value))}
  end
end
