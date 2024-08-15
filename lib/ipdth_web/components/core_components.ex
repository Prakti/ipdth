defmodule IpdthWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such as modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import IpdthWeb.Gettext

  @badge_styles %{
    "gray" => "bg-gray-100 text-gray-700 ring-gray-600/40",
    "zinc" => "bg-zinc-100 text-zinc-700 ring-zinc-600/40",
    "neutral" => "bg-neutral-100 text-neutral-700 ring-neutral-600/40",
    "stone" => "bg-stone-100 text-stone-700 ring-stone-600/40",
    "red" => "bg-red-100 text-red-700 ring-red-600/40",
    "orange" => "bg-orange-100 text-orange-700 ring-orange-600/40",
    "amber" => "bg-amber-100 text-amber-700 ring-amber-600/40",
    "yellow" => "bg-yellow-100 text-yellow-700 ring-yellow-600/40",
    "lime" => "bg-lime-100 text-lime-700 ring-lime-600/40",
    "green" => "bg-green-100 text-green-700 ring-green-600/40",
    "emerald" => "bg-emerald-100 text-emerald-700 ring-emerald-600/40",
    "teal" => "bg-teal-100 text-teal-700 ring-teal-600/40",
    "cyan" => "bg-cyan-100 text-cyan-700 ring-cyan-600/40",
    "sky" => "bg-sky-100 text-sky-700 ring-sky-600/40",
    "blue" => "bg-blue-100 text-blue-700 ring-blue-600/40",
    "indigo" => "bg-indigo-100 text-indigo-700 ring-indigo-600/40",
    "violet" => "bg-violet-100 text-violet-700 ring-violet-600/40",
    "purple" => "bg-purple-100 text-purple-700 ring-purple-600/40",
    "fuchsia" => "bg-fuchsia-100 text-fuchsia-700 ring-fuchsia-600/40",
    "pink" => "bg-pink-100 text-pink-700 ring-pink-600/40",
    "rose" => "bg-rose-100 text-rose-700 ring-rose-600/40"
  }

  @doc """
  Renders a generic badge
  """
  attr :color, :string, required: true
  slot :inner_block, required: true

  def badge(assigns) do
    color = assigns.color || "gray"
    assigns = assign(assigns, coloring: @badge_styles[color])

    ~H"""
    <div class={[
      "rounded-md px-2.5 py-1.5 text-xs",
      "font-bold leading-none ring-1 ring-inset",
      "align-middle text-center",
      @coloring
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders the user status as a colored badge.
  """
  attr :user_status, :string, required: true

  def user_status_badge(assigns) do
    ~H"""
    <.badge color={(@user_status == "confirmed" && "sky") || "yellow"}>
      <%= @user_status %>
    </.badge>
    """
  end

  @doc """
  Renders the roles badge of a user.
  """
  attr :role, :string, required: true

  def user_role_badge(assigns) do
    ~H"""
    <.badge color="zinc"><%= @role %></.badge>
    """
  end

  @doc """
  Renders the status badge of an Agent
  """
  attr :status, :atom, required: true

  def agent_status_badge(assigns) do
    assigns =
      assign(assigns,
        color:
          case assigns.status do
            :inactive -> "zinc"
            :testing -> "yellow"
            :active -> "green"
            :backoff -> "orange"
            :error -> "red"
          end
      )

    ~H"""
    <.badge color={@color}><%= @status %></.badge>
    """
  end

  @doc """
  Renders a dropdown menu.

  ## Examples

      <.dropdown_menu id="menu_a">
        Menu Title
        <:menu_items>Item 1</:menu_items>
        <:menu_items>Item 2</:menu_items>
        <:menu_items>Item 3</:menu_items>
        <:menu_items>Item 4</:menu_items>
      </.dropdown_menu>
  """
  attr :id, :string, required: true
  slot :menu_items, required: true
  slot :inner_block, required: true

  def dropdown_menu(assigns) do
    ~H"""
    <div id={@id} phx-remove={hide("#{@id}-container")} class="relative mt-2">
      <button class="relative w-full py-2" phx-click={toggle_visibility("##{@id}-container")}>
        <%= render_slot(@inner_block) %>
      </button>
      <.focus_wrap
        id={"#{@id}-container"}
        phx-click-away={hide("##{@id}-container")}
        class="absolute mt2 w-40 rounded bg-white shadow-xl hidden border border-color-zinc-400 z-50"
      >
        <ul class="flex flex-col gap-2 py-2 justify-end items-stretch">
          <li
            :for={item <- @menu_items}
            class="sm:px-6 lg:px-8 hover:bg-amber-500 text-zinc-900 hover:text-white"
          >
            <%= render_slot(item) %>
          </li>
        </ul>
      </.focus_wrap>
    </div>
    """
  end

  @doc """
  Renders a split-button.

  ## Examples

    <.split_button>
      Edit
      <:buttons>Activate</:buttons>
      <:buttons>Delete </:buttons>
    </.split-button>
  """
  attr :id, :string, required: true
  slot :buttons, required: true
  slot :inner_block, required: true

  def split_button(assigns) do
    ~H"""
    <div id={@id} phx-remove={hide("#{@id}-container")} class="relative w-fit mt-2">
      <div class="relative">
        <button class={[
          "rounded-l-md bg-amber-500  py-1 px-3",
          "text-sm font-semibold leading-6 text-white ",
          "border-b-2 border-amber-600 shadow border-r-2",
          "hover:border-amber-500 hover:bg-amber-400",
          "active:border-amber-600 active:bg-amber-600 active:shadow-inner"
        ]}>
          <%= render_slot(@inner_block) %>
        </button>
        <button
          class={[
            "rounded-r-md bg-amber-500  py-1 px-1",
            "text-sm font-semibold leading-6 text-white ",
            "border-b-2 border-amber-600 shadow",
            "hover:border-amber-500 hover:bg-amber-400",
            "active:border-amber-600 active:bg-amber-600 active:shadow-inner"
          ]}
          phx-click={toggle_visibility("##{@id}-container")}
        >
          <.icon name="hero-chevron-down" class="w-5 h-5" />
        </button>
      </div>
      <.focus_wrap
        id={"#{@id}-container"}
        phx-click-away={hide("##{@id}-container")}
        class={[
          "absolute right-0 mt-1 w-fit rounded bg-white shadow-xl hidden border z-50",
          "border-b-2 border-amber-500"
        ]}
      >
        <ul class="flex flex-col justify-end items-stretch">
          <li
            :for={button <- @buttons}
            class={[
              "px-6 py-2 first:rounded-t last:rounded-b hover:bg-amber-400 text-white",
              "last:border-amber-600 last:hover:border-amber-500",
              "bg-amber-500 active:bg-amber-600 cursor-pointer"
            ]}
          >
            <%= render_slot(button) %>
          </li>
        </ul>
      </.focus_wrap>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-md bg-amber-500  py-1 px-3",
        "text-sm font-semibold leading-6 text-white ",
        "border-b-2 border-amber-600 shadow",
        "hover:border-amber-500 hover:bg-amber-400",
        "active:border-amber-600 active:bg-amber-600 active:shadow-inner",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a navbar.

  ## Examples
    <.navbar>
      <:nav_item id={:agents} route={~p"/agents"}>
        Agents
      </:nav_item>
      <:nav_item id={:tournaments} route={~p"/tournaments"}>
        Tournaments
      </:nav_item>
    </.navbar>
  """
  attr :active_page, :string, default: ""

  slot :nav_item do
    attr :id, :string, required: true
    attr :route, :string, required: true
  end

  def navbar(assigns) do
    ~H"""
    <nav class="nav text-lg font-semibold">
      <ul :if={@nav_item != []} class="flex items-center">
        <li
          :for={item <- @nav_item}
          class={"#{if @active_page == item[:id],
            do: "cursor-pointer border-b-2 border-amber-500 border-opacity-100 p-4 text-amber-500",
            else: "cursor-pointer border-b-2 border-amber-500 border-opacity-0 p-4 duration-200 hover:border-opacity-100 hover:text-amber-500"}"}
        >
          <a href={item[:route]}><%= render_slot(item) %></a>
        </li>
      </ul>
    </nav>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed bottom-10 right-10 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-md text-white border-b-4",
        @kind == :info && "bg-green-500 border-b-green-600",
        @kind == :error && "bg-red-500 border-b-red-600"
      ]}
      {@rest}
    >
      <div class="flex flex-row flex-nowrap item-center gap-2">
        <div class="flex-none h-10 w-10">
          <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-10 w-10" />
          <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-10 w-10" />
        </div>
        <div class="flex-grow flex-shrink">
          <p :if={@title} class="text-sm font-semibold leading-6">
            <%= @title %>
          </p>
          <p class="mt-2 text-sm leading-5"><%= msg %></p>
        </div>
      </div>
      <button type="button" class="group absolute top-1 right-1 p-1" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-60 group-hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="client-error"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show(".phx-client-error #client-error")}
      phx-connected={hide("#client-error")}
      hidden
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>

    <.flash
      id="server-error"
      kind={:error}
      title="Something went wrong!"
      phx-disconnected={show(".phx-server-error #server-error")}
      phx-connected={hide("#server-error")}
      hidden
    >
      Hang in there while we get back on track
      <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white
        shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc """
  Render the filters for a flop_table.
  """
  attr :meta, Flop.Meta, required: true
  attr :fields, :list, required: true

  def flop_table_filters(assigns) do
    assigns = assign(assigns, :meta_form, Phoenix.Component.to_form(assigns.meta))

    ~H"""
    <.form id="agent-filter" for={@meta_form} phx-change="filter">
      <div class="flex flex-row gap-4">
        <Flop.Phoenix.filter_fields :let={i} form={@meta_form} fields={@fields}>
          <.input field={i.field} label={i.label} type={i.type} class="" {i.rest} />
        </Flop.Phoenix.filter_fields>
      </div>
    </.form>
    """
  end

  @doc """
  Render frame for the table, that can show an empty state image in case there
  is not content to be shown in the table.
  """
  attr :meta, Flop.Meta, required: true
  attr :path, :string, required: true
  attr :page_sizes, :list, default: [10, 20, 50, 100]
  attr :filter_fields, :list, default: []
  attr :empty?, :boolean, required: true
  attr :empty_icon, :string, default: "hero-inbox-solid"
  attr :empty_message, :string, required: true

  slot :inner_block, required: true

  def table_frame(assigns) do
    if assigns.empty? do
      ~H"""
      <.flop_table_filters :if={@filter_fields != []} meta={@meta} fields={@filter_fields} />
      <div class={[
        "flex flex-row flex-nowrap justify-center items-center",
        "p-8 mt-12 rounded-lg border border-zinc-200 shadow-md"
      ]}>
        <.icon name={@empty_icon} class="text-zinc-600 mr-4 w-12 h-12" />
        <div class=""><%= @empty_message %></div>
      </div>
      """
    else
      ~H"""
      <.flop_table_filters :if={@filter_fields != []} meta={@meta} fields={@filter_fields} />
      <div class="mt-12">
        <.pagination meta={@meta} path={@path} page_sizes={@page_sizes} />
        <div class="overflow-hidden rounded-lg border border-zinc-200 shadow-md mt-2">
          <%= render_slot(@inner_block) %>
        </div>
        <.pagination meta={@meta} path={@path} page_sizes={@page_sizes} />
      </div>
      """
    end
  end

  @doc """
  Renders a table with generic styling.

  TODO: 2024-04-28 - Rethink display of table-actions

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-hidden rounded-lg border border-zinc-200 shadow-md mt-12">
      <table class="w-full border-collapse bg-white text-left text-sm">
        <thead class="bg-zinc-50 sticky top-0 border-b-2 border-zinc-200">
          <tr>
            <th :for={col <- @col} class="px-6 py-4 font-medium text-zinc-900"><%= col[:label] %></th>
            <th class="px-6 py-4 font-medium text-zinc-900">
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="divide-y divide-zinc-100"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="hover:bg-zinc-50 group">
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["px-6 py-4", @row_click && "hover:cursor-pointer"]}
            >
              <%= render_slot(col, @row_item.(row)) %>
            </td>
            <td class="">
              <div :if={@action != []} class="group-hover:visible invisible">
                <span :for={action <- @action} class="">
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defdelegate flop_table(assigns), to: Flop.Phoenix, as: :table

  def prev_page_link_content(assigns) do
    ~H"""
    <i class="hero-chevron-left" />
    """
  end

  def next_page_link_content(assigns) do
    ~H"""
    <i class="hero-chevron-right" />
    """
  end

  defp page_size_class(old, old) do
    ["font-bold rounded bg-amber-500 text-white"]
  end

  defp page_size_class(_old, _new) do
    []
  end

  @doc """
  Render a cursor pagination bar including page size control
  """
  attr :meta, Flop.Meta, required: true
  attr :path, :string, required: true
  attr :page_sizes, :list, required: true

  def pagination(assigns) do
    ~H"""
    <div class="flex flex-row mt-3 text-sm justify-between place-items-baseline">
      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        path={@path}
        opts={[
          disabled_class: "text-zinc-500 border",
          wrapper_attrs: [
            class: "flex flex-row place-items-center"
          ],
          previous_link_content: prev_page_link_content(assigns),
          previous_link_attrs: [
            class: "px-2 py-1 border-l border-y border-zinc-200 rounded-l-md shadow-sm"
          ],
          next_link_content: next_page_link_content(assigns),
          next_link_attrs: [
            class: "px-2 py-1 border border-zinc-200 rounded-r-md shadow-sm"
          ]
        ]}
      />
      <div class="flex flex-row flex-nowrap space-x-1">
        <span class="px-1">Page size:</span>
        <.link
          :for={size <- @page_sizes}
          phx-click="page-size"
          phx-value-size={size}
          class={[
            "px-1",
            page_size_class(@meta.page_size, size)
          ]}
        >
          <%= size %>
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def toggle_visibility(js \\ %JS{}, selector) do
    JS.toggle(js,
      to: selector,
      in: {"ease-out duration-100", "opacity-0 scale-95", "opacity-100 scale-100"},
      out: {"ease-out duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  def flop_table_options(assigns) do
    [
      symbol_asc: ~H"""
      <i class="hero-chevron-up-mini ml-1" />
      """,
      symbol_desc: ~H"""
      <i class="hero-chevron-down-mini ml-1" />
      """,
      symbol_unsorted: ~H"""
      <i class="hero-chevron-up-down-mini ml-1" />
      """,
      table_attrs: [
        class: "w-full border-collapse bg-white text-left text-sm"
      ],
      thead_attrs: [
        class: "bg-zinc-50 border-b-2 border-zinc-200"
      ],
      thead_th_attrs: [
        class: "px-6 py-4 font-medium text-zinc-900"
      ],
      th_wrapper_attrs: [
        class: "flex flex-row"
      ],
      tbody_attrs: [
        class: "divide-y divide-zinc-100"
      ],
      tbody_tr_attrs: [
        class: "hover:bg-zinc-50 group"
      ],
      tbody_td_attrs: [
        # TODO: 2024-08-14 - Make max-w-md configurable!
        class: "px-6 py-4 truncate whitespace-nowrap max-w-md hover:cursor-pointer"
      ]
    ]
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(IpdthWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(IpdthWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
