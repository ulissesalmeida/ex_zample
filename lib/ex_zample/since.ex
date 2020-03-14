defmodule ExZample.Since do
  @moduledoc false

  # NOTE: Drop support to Elixir 1.6 before release 1.0.0
  defmacro since(version) do
    quote do
      if Version.match?(System.version(), ">= 1.7.0") do
        @doc since: unquote(version)
      else
        @since unquote(version)
      end
    end
  end
end
