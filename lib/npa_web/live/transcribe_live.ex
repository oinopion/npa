defmodule NPAWeb.TranscribeLive do
  use NPAWeb, :live_view

  alias NPA.Transcriber
  alias Npa.History

  @text_limit 100
  @history_debounce_ms 2000
  @codewords_colors Transcriber.code_words()
                    |> Enum.zip(Stream.cycle(~w"cyan violet teal blue emerald indigo"))
                    |> Enum.into(%{})

  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(
        text_limit: @text_limit,
        text: "",
        transcription: [],
        history: History.new()
      )
      |> start_debouncer()
      |> assign_new_text(Map.get(params, "text", ""))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <section>
      <form id="form" phx-hook="history" class="m-0">
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

      <dl id="transcription" class="m-0 px-1 py-2">
        <%= for {word, codewords} <- @transcription do %>
          <dt class="word font-bold pt-1"><%= word %>:</dt>
          <dd class="leading-8 pb-1">
            <%= for {bg_cls, cw} <- with_bg_classes(codewords) do %>
              <span class={"codeword bg-#{bg_cls}-700 text-white p-1 rounded"}><%= cw %></span>
            <% end %>
          </dd>
        <% end %>
      </dl>
    </section>

    <%= if @history != [] do %>
      <section id="history" class="border-t-2 border-zinc-200">
        <p>Previous phrases</p>
        <ol>
          <%= for text <- @history do %>
            <li><%= text %></li>
          <% end %>
        </ol>
        <button phx-click="clear_history">Clear history</button>
      </section>
    <% end %>
    """
  end

  def handle_event("input_change", %{"text" => new_text}, socket) do
    socket =
      socket
      |> assign_new_text(new_text)
      |> debounce_history_storage()

    {:noreply, socket}
  end

  def handle_event("restore_history", %{"history" => json_text}, socket) do
    case Jason.decode(json_text) do
      {:ok, stored_entries} when is_list(stored_entries) ->
        history =
          socket.assigns[:history]
          |> History.restore(stored_entries)

        {:noreply, assign(socket, history: history)}
    end
  end

  def handle_event("clear_history", _, socket) do
    history = History.new()

    socket =
      socket
      |> assign(history: history)
      |> push_event("store_history", %{"history" => Jason.encode!(history)})
      |> cancel_history_storage_debounce()

    {:noreply, socket}
  end

  def handle_info(:store_history, socket) do
    case socket.assigns[:history] do
      [] ->
        {:noreply, socket}

      history ->
        socket =
          socket
          |> push_event("store_history", %{"history" => Jason.encode!(history)})

        {:noreply, socket}
    end
  end

  defp assign_new_text(socket, new_text) do
    new_text =
      new_text
      |> String.slice(0, @text_limit)
      |> String.trim()

    transcription = NPA.Transcriber.transcribe_phrase(new_text)

    current_text = socket.assigns[:text]
    current_history = socket.assigns[:history]
    new_history = History.record(current_history, current_text, new_text)

    socket
    |> assign(
      text: new_text,
      transcription: transcription,
      history: new_history
    )
  end

  defp start_debouncer(socket) do
    if connected?(socket) do
      {:ok, debouncer} = Debouncer.start_link(@history_debounce_ms)
      assign(socket, debouncer: debouncer)
    else
      assign(socket, debouncer: nil)
    end
  end

  defp debounce_history_storage(socket) do
    if connected?(socket) do
      socket.assigns[:debouncer]
      |> Debouncer.schedule(:store_history)
    end

    socket
  end

  defp cancel_history_storage_debounce(socket) do
    socket.assigns[:debouncer]
    |> Debouncer.cancel()

    socket
  end

  defp with_bg_classes(transcription) do
    transcription
    |> Enum.map(fn code_word ->
      {Map.get(@codewords_colors, code_word, "bg-black"), code_word}
    end)
  end
end
