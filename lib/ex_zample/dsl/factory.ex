defmodule ExZample.DSL.Factory do
  @moduledoc false

  @doc false
  def define({scope, name, block}, caller) do
    factory_module = module(scope, name, caller)
    converted_dsl = Macro.prewalk(block, &converted_dsl/1)

    contents =
      quote location: :keep do
        @moduledoc false
        import ExZample

        @behaviour ExZample

        unquote(converted_dsl)
      end

    Module.create(factory_module, contents, caller)
  end

  defp module(scope, name, caller),
    do: Module.concat(caller.module, module_name(scope, name))

  defp module_name(:global, name), do: Macro.camelize("#{name}_factory")

  defp module_name(scope, name), do: Macro.camelize("#{scope}_#{name}_factory")

  defp converted_dsl({:example, _context, [[do: block]]}) do
    quote location: :keep do
      @impl ExZample
      def example do
        unquote(block)
      end
    end
  end

  defp converted_dsl({:example, _context, [args, [do: block]]}) do
    quote location: :keep do
      @impl ExZample
      def example(unquote(args)) do
        unquote(block)
      end
    end
  end

  defp converted_dsl(ast), do: ast

  @doc false
  def manifest(caller) do
    caller.module
    |> Module.get_attribute(:ex_zample_factories)
    |> Enum.map(fn {scope, name, _block} ->
      {scope, name, module(scope, name, caller)}
    end)
  end
end
