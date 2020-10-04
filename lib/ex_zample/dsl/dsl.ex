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
              id: sequence(:user_id),
              first_name: "Abili"
              last_name: "de bob"
            }
          end
        end

        sequence :user_id
      end

  It will generate the modules, functions and the aliases manifest to be loaded
  when the `ex_zample` app starts. Then, to use your factories, don't forget to
  start your app. For example:

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

  @type scoped_name :: {scope :: atom, name :: atom}
  @type name_or_scoped_name :: name :: atom | [scoped_name]

  defguardp is_name_or_scoped_name(term) when is_list(term) or is_atom(term)

  @doc false
  defmacro __using__(opts \\ []) do
    quote location: :keep, bind_quoted: [opts: opts] do
      import ExZample.DSL, except: [sequence: 2, sequence: 1]

      Module.register_attribute(__MODULE__, :ex_zample_factories, accumulate: true)
      Module.register_attribute(__MODULE__, :ex_zample_sequences, accumulate: true)

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
        &ExZample.DSL.Factory.define(&1, caller)
      )

      Enum.each(
        @ex_zample_sequences,
        &ExZample.DSL.Sequence.define(&1, caller)
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
  @spec factory(name_or_scoped_name, do: Macro.t()) :: Macro.t()
  defmacro factory(name_or_scoped_name, do: block)
           when is_name_or_scoped_name(name_or_scoped_name) do
    {scope, name} = parse_name_and_scope(name_or_scoped_name)

    quote location: :keep, bind_quoted: [scope: scope, name: name, block: Macro.escape(block)] do
      @ex_zample_factories %ExZample.DSL.Factory{
        scope: the_scope(scope, @ex_zample_opts),
        name: name,
        block: block,
        ecto_repo: @ex_zample_opts[:ecto_repo]
      }
    end
  end

  @doc """
  Defines a sequence function with a given alias `name` and a anonymus function
  on `return` as value transformation.

  ## Examples

      def_sequence(:user_id, return: &("user_\#{&1}")

      # later you can invoke like this:
      ExZample.sequence(:user_id)
      "user_1"

  A function will be generated in the current module following the pattern:
  `{scope}_{sequence_name}_sequence`.
  """
  since("0.10.0")
  @spec def_sequence(name :: atom, return: ExZample.sequence_fun()) :: Macro.t()
  defmacro def_sequence(name, return: fun) when is_atom(name) do
    quote location: :keep,
          bind_quoted: [scope: nil, name: name, fun: Macro.escape(fun)] do
      @ex_zample_sequences {the_scope(scope, @ex_zample_opts), name, fun}
    end
  end

  @doc """
  Defines a sequence function with a optional `scope`, mandatory `name` and an
  optional anonymus function in `return` as value transformation.

  ## Examples

      def_sequence(:user_id)

      def_sequence(scoped: :user_id, return: &"user_\#{&1}")

      # later you can invoke like this:

      ExZample.sequence(:user_id)
      1

      ExZample.ex_zample(ex_zample_scope: :scoped)
      ExZample.sequence(:user_id)
      "user_1"

  A function will be generated in the current module following the pattern:
  `{scope}_{sequence_name}_sequence`.
  """
  since("0.10.0")

  @spec def_sequence(Keyword.t() | atom) ::
          Macro.t()
  defmacro def_sequence(opts_or_name) when is_atom(opts_or_name) do
    name = opts_or_name

    quote location: :keep,
          bind_quoted: [scope: nil, name: name, fun: nil] do
      @ex_zample_sequences {the_scope(scope, @ex_zample_opts), name, nil}
    end
  end

  defmacro def_sequence(opts_or_name) when is_list(opts_or_name) do
    opts = opts_or_name
    {fun_opts, name_opts} = Keyword.split(opts, [:return])
    {scope, name} = parse_name_and_scope(name_opts)

    fun = if fun = fun_opts[:return], do: Macro.escape(fun)

    quote location: :keep,
          bind_quoted: [scope: scope, name: name, fun: fun] do
      @ex_zample_sequences {the_scope(scope, @ex_zample_opts), name, fun}
    end
  end

  @doc "Sames as def_sequence/2"
  since("0.7.0")
  @deprecated "Use def_sequence/2 instead"
  defmacro sequence(name, return: fun) when is_atom(name) do
    quote location: :keep,
          bind_quoted: [scope: nil, name: name, fun: Macro.escape(fun)] do
      @ex_zample_sequences {the_scope(scope, @ex_zample_opts), name, fun}
    end
  end

  @doc "Sames as def_sequence/1"
  since("0.7.0")
  @deprecated "Use def_sequence/1 instead"
  defmacro sequence(opts_or_name) when is_atom(opts_or_name) do
    name = opts_or_name

    quote location: :keep,
          bind_quoted: [scope: nil, name: name, fun: nil] do
      @ex_zample_sequences {the_scope(scope, @ex_zample_opts), name, nil}
    end
  end

  defmacro sequence(opts_or_name) when is_list(opts_or_name) do
    opts = opts_or_name
    {fun_opts, name_opts} = Keyword.split(opts, [:return])
    {scope, name} = parse_name_and_scope(name_opts)

    fun = if fun = fun_opts[:return], do: Macro.escape(fun)

    quote location: :keep,
          bind_quoted: [scope: scope, name: name, fun: fun] do
      @ex_zample_sequences {the_scope(scope, @ex_zample_opts), name, fun}
    end
  end

  defp parse_name_and_scope([{scope, name}]) when is_atom(name) and is_atom(scope),
    do: {scope, name}

  defp parse_name_and_scope(name) when is_atom(name), do: {nil, name}

  @doc false
  def the_scope(scope, opts \\ []),
    do: if(scope, do: scope, else: opts[:scope] || :global)

  @doc false
  def create_manifest(caller, _binary) do
    factories = __MODULE__.Factory.manifest(caller)
    sequences = __MODULE__.Sequence.manifest(caller)

    file_name = Macro.underscore(caller.module) <> ".ex_zample_manifest.elixir"
    file = Path.join([Mix.Project.build_path(), "/ex_zample/manifest/", file_name])

    Manifest.write!(file, factories, sequences)
  end
end
