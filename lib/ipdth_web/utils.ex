defmodule IpdthWeb.Utils do
  @moduledoc """
  Utility functions for usage in LiveViews.
  """
  alias Phoenix.LiveView.Socket

  @doc """
  Builds a path using Flop-parameters that can be provided from
  various sources: Map, Socket, Flop, Flop.Meta. Returns the base path
  in case no source works properly.
  """
  def build_path(base_path, source, opts \\ [])

  def build_path(base_path, %Socket{} = socket, _opts) do
    build_path(base_path, Map.get(socket.assigns, :meta, nil))
  end

  def build_path(base_path, %Flop.Meta{} = meta, _opts) do
    Flop.Phoenix.build_path(base_path, meta.flop, backend: meta.backend, for: meta.schema)
  end

  def build_path(base_path, %Flop{} = flop, opts) do
    Flop.Phoenix.build_path(base_path, flop, opts)
  end

  def build_path(base_path, params, opts) when is_map(params) do
    Flop.Phoenix.build_path(base_path, params, opts)
  end

  def build_path(base_path, _, _), do: base_path

  def page_size_to_path(base_path, meta, size) do
    flop = %Flop{meta.flop | first: size}
    build_path(base_path, flop, backend: meta.backend, for: meta.schema)
  end

  def empty_filters?(flop) do
    Enum.all?(flop.filters, fn filter -> filter.value == nil end)
  end
end
