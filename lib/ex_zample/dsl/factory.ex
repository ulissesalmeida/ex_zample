defmodule ExZample.DSL.Factory do
  @moduledoc false

  defstruct ~w(scope name block ecto_repo)a

  @doc false
  def define(
        %__MODULE__{
          scope: scope,
          name: name,
          block: block,
          ecto_repo: ecto_repo
        },
        caller
      ) do
    init_stats = %{has_repo?: false}
    factory_module = module(scope, name, caller)
    {converted_dsl, stats} = Macro.prewalk(block, init_stats, &convert_dsl/2)

    contents =
      quote location: :keep do
        @moduledoc false
        import ExZample

        @behaviour ExZample

        unquote(converted_dsl)

        if not unquote(stats.has_repo?) && unquote(ecto_repo) do
          @impl ExZample
          def ecto_repo, do: unquote(ecto_repo)
        end
      end

    Module.create(factory_module, contents, caller)
  end

  defp module(scope, name, caller),
    do: Module.concat(caller.module, module_name(scope, name))

  defp module_name(:global, name), do: Macro.camelize("#{name}_factory")

  defp module_name(scope, name), do: Macro.camelize("#{scope}_#{name}_factory")

  defp convert_dsl({:example, _context, [[do: block]]}, stats) do
    ast =
      quote location: :keep do
        @impl ExZample
        def example do
          unquote(block)
        end
      end

    {ast, stats}
  end

  defp convert_dsl({:example, _context, [args, [do: block]]}, stats) do
    ast =
      quote location: :keep do
        @impl ExZample
        def example(unquote(args)) do
          unquote(block)
        end
      end

    {ast, stats}
  end

  defp convert_dsl({:ecto_repo, _context, [[do: block]]}, stats) do
    ast =
      quote location: :keep do
        @impl ExZample
        def ecto_repo do
          unquote(block)
        end
      end

    {ast, Map.put(stats, :has_repo?, true)}
  end

  defp convert_dsl(ast, stats), do: {ast, stats}

  @doc false
  def manifest(caller) do
    caller.module
    |> Module.get_attribute(:ex_zample_factories)
    |> Enum.map(fn %__MODULE__{scope: scope, name: name} ->
      {scope, name, module(scope, name, caller)}
    end)
  end
end
