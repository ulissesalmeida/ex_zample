defmodule ExZample.DSL do
  @moduledoc """
  Defines a domain-speficic language(DSL) to simplify the creation of your
  factories.

  You can use this DSL by using by defining a module and adding the `use`
  directive. For example:

      defmodule MyApp.Factories do
        use ExZample.DSL

        alias MyApp.User

        factory :user do
          example do
            %User{
              id: 33,
              first_name: "Abili"
              last_name: "de bob"
            }
          end
        end
      end

  It will generate the modules and the aliases manifest to be loaded when the
  `ex_zample` app starts. Then, to use your factories, don't forget to start
  your app. For example:

        #  in your test_helper.exs
        :ok = Application.ensure_started(:ex_zample)

  This way, all factorites your defined using the `ExZample.DSL` will be
  loaded module.

  ## Options

  You can pass the following options to the `use` directive:

  * `scope` (default: `:global`), the `:scope` that all aliases of factories
    will be stored
  """
  alias ExZample.Manifest

  import ExZample.Since

  @doc false
  defmacro __using__(opts \\ []) do
    quote location: :keep, bind_quoted: [opts: opts] do
      import ExZample.DSL

      Module.register_attribute(__MODULE__, :ex_zample_factories, accumulate: true)

      @ex_zample_opts opts
      @before_compile ExZample.DSL
      @after_compile {ExZample.DSL, :create_manifest}
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote location: :keep, bind_quoted: [caller: Macro.escape(__CALLER__)] do
      Enum.each(
        @ex_zample_factories,
        &def_factory(&1, caller)
      )
    end
  end

  @doc """
  Defines a module factory with helpers imported by default.

  If you pass an `atom` for factory name, such as `user`, the module will be
  generated with `UserFactory`. If you pass a scope, like: `my_app: :user`, the
  module name will become `MyAppUserFactory`.

  The factory body has all functions from `ExZample` imported. It also has access
  to `example` DSL helper that generates a function definition with behaviour
  annotations. Taking those helpers out, everything else work as normal Elixir
  module.
  """
  since("0.6.0")
  @spec factory(name :: atom | [{scope :: atom, name :: atom}], do: Macro.t()) :: Macro.t()
  defmacro factory(name_or_scoped_name, do: block)
           when is_list(name_or_scoped_name) or is_atom(name_or_scoped_name) do
    {scope, name} =
      case name_or_scoped_name do
        [{scope, name}] -> {scope, name}
        name when is_atom(name) -> {nil, name}
      end

    quote location: :keep, bind_quoted: [scope: scope, name: name, block: Macro.escape(block)] do
      the_scope = if scope, do: scope, else: @ex_zample_opts[:scope] || :global
      @ex_zample_factories {the_scope, name, block}
    end
  end

  @doc false
  def def_factory({scope, name, block}, caller) do
    factory_module = factory_module(scope, name, caller)
    converted_dsl = Macro.prewalk(block, &converted_dsl/1)

    contents =
      quote location: :keep do
        @moduledoc false
        import ExZample

        @behaviour ExZample

        unquote(converted_dsl)
      end

    Module.create(factory_module, contents, caller)
    ExZample.config_aliases(scope, %{name => factory_module})
  end

  defp factory_module(scope, name, caller),
    do: Module.concat(caller.module, factory_module_name(scope, name))

  defp factory_module_name(:global, name), do: Macro.camelize("#{name}_factory")

  defp factory_module_name(scope, name), do: Macro.camelize("#{scope}_#{name}_factory")

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
  def create_manifest(caller, _binary) do
    factories =
      caller.module
      |> Module.get_attribute(:ex_zample_factories)
      |> Enum.map(fn {scope, name, _block} ->
        {scope, name, factory_module(scope, name, caller)}
      end)

    file_name = Macro.underscore(caller.module) <> ".ex_zample_manifest.elixir"
    file = Path.join(Mix.Project.manifest_path(), file_name)

    Manifest.write!(file, factories)
  end
end
