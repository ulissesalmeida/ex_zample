defmodule ExZample.DSL.Sequence do
  @moduledoc false

  @doc false
  def define({scope, name, block}, caller) do
    function_name = function_name(scope, name)
    block = block || quote location: :keep, do: & &1

    content =
      quote bind_quoted: [function_name: function_name, block: Macro.escape(block)] do
        def unquote(function_name)(), do: unquote(block)
      end

    Module.eval_quoted(caller, content)
  end

  defp function_name(:global, name),
    do: "#{name}_sequence" |> Macro.underscore() |> String.to_atom()

  defp function_name(scope, name),
    do: "#{scope}_#{name}_sequence" |> Macro.underscore() |> String.to_atom()

  @doc false
  def manifest(caller) do
    caller.module
    |> Module.get_attribute(:ex_zample_sequences)
    |> Enum.map(fn {scope, name, _block} ->
      {scope, name, {caller.module, function_name(scope, name), []}}
    end)
  end
end
