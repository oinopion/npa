defmodule NPAWeb.TranscribeLive do
  require Logger
  use NPAWeb, :live_view

  alias NPA.Transcriber
  alias Npa.History

  @text_limit 100
  @history_debounce_ms 2000
  @codewords_colors Transcriber.code_words()
                    |> Enum.zip(Stream.cycle(~w"cyan violet teal blue emerald indigo"))
                    |> Enum.into(%{})

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        text_limit: @text_limit,
        text: "",
        transcription: [],
        history: History.new(),
        last_text_param: ""
      )
      |> start_debouncer()

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    text = Map.get(params, "text", "")

    socket =
      socket
      |> assign_new_text(text)
      |> assign(last_text_param: text)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <section>
      <form id="form" phx-hook="history" class="m-0 relative w-full" phx-submit="update_text_param">
        <input
          phx-change="input_change"
          phx-blur="update_text_param"
          id="text"
          name="text"
          type="text"
          value={@text}
          placeholder="Phrase to spell out"
          maxlength={@text_limit}
          class="w-full rounded border-2 border-indigo-600"
        />
        <button
          id="clear_text"
          phx-click="clear_text"
          type="button"
          class="absolute inset-y-0 end-0 flex items-center p-3 text-indigo-600"
        >
          <.icon name="hero-x-mark" />
        </button>
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
      <section id="history" class="border-t-2 border-zinc-200 my-2 px-1 py-2">
        <div class="flex justify-between py-1">
          <h2 class="font-semibold">Previous phrases</h2>
          <button phx-click="clear_history"><.icon name="hero-trash" /></button>
        </div>
        <ol>
          <%= for text <- @history do %>
            <li class="leading-8">
              <.link patch={~p"/?text=#{text}"} class="rounded p-1 bg-indigo-200"><%= text %></.link>
            </li>
          <% end %>
        </ol>
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

  def handle_event("update_text_param", _params, socket) do
    # This handler is invoked from form submit and input blur and params will be different depending on the source event
    %{text: text, last_text_param: last_text_param} = socket.assigns

    socket =
      if text != last_text_param do
        socket
        |> assign(last_text_param: text)
        |> push_patch(to: ~p"/?text=#{text}")
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("clear_text", _, socket) do
    socket =
      socket
      |> assign_new_text("")

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
