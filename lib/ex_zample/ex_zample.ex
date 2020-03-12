defmodule ExZample do
  @moduledoc """
  ExZample is a factory library based on Elixir behaviours.
  """

  alias ExZample.{Sequence, SequenceSupervisor}

  @doc """
  Invoked every time you build your data using `ExZample` module.

  You need to return a struct with example values.

  This callback is optional when the module given is a struct. It will use
  the struct default values if no callback is given.
  """
  @callback example() :: struct

  @type factory :: module
  @type sequence_fun :: (pos_integer -> term)

  @optional_callbacks example: 0

  defguardp is_greater_than_0(term) when is_integer(term) and term > 0

  @doc """
  Creates aliases for your factories to simplify the build calls.

  A `aliases` should be a map with atom keys and values as `factory` compatible
  modules. If you call with repeated keys this function will fail. This function
  is ideal to be called once, for example in your `test_helper.ex` file.

  ## Examples
      iex> ExZample.add_aliases(%{user: Factories.User})
      ...> ExZample.build(:user)
      %User{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}
  """
  @spec add_aliases(%{required(atom) => factory}) :: :ok
  def add_aliases(aliases) when is_map(aliases), do: add_aliases(:global, aliases)

  @doc """
  Same as `add_aliases/1`, but you can define a different scope.

  This function is specially useful for umbrella apps where each app can define
  their factories without leaking any aliases to other apps. You can enforce the
  current scope with `ex_zample/1`.

  ## Examples
      iex> ExZample.add_aliases(:my_app, %{user: Factories.User})
      ...> ExZample.ex_zample(%{ex_zample_scope: :my_app})
      ...> ExZample.build(:user)
      %User{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}
  """
  @spec add_aliases(atom, %{required(atom) => factory}) :: :ok
  def add_aliases(scope, aliases) when is_map(aliases) do
    config = get_config(scope)
    current_aliases = Map.get(config, :aliases, %{})

    updated_aliases =
      Map.merge(current_aliases, aliases, fn factory_alias, current_factory, new_factory ->
        if current_factory == new_factory do
          current_factory
        else
          raise ArgumentError, """
          The alias #{inspect(factory_alias)} already exists!
          It is registered with the factory #{inspect(current_factory)} and
          can't be replaced with the new #{inspect(new_factory)} in #{inspect(scope)} scope.
          Rename the alias or add it in a different scope.
          """
        end
      end)

    put_config(scope, Map.put(config, :aliases, updated_aliases))
    :ok
  end

  @doc """
  Creates a sequence with the given `name`.

  A sequence is global runtime counter that can be invoked with `sequence/1`. The
  default counter starts from `1` and increments `1` by `1`.

  ## Examples
      iex> ExZample.create_sequence(:user_id)
      ...> Enum.map(1..10, fn _ -> ExZample.sequence(:user_id) end)
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  """
  @spec create_sequence(atom) :: :ok
  def create_sequence(name), do: create_sequence(:global, name, & &1)

  @doc """
  Same as `create_sequence/1`, but you can define a different scope or a
  sequence function.

  When use with `scope` and `name` you define scoped global counter, it's
  useful for umbrella apps for example.

  When you use `name` and `sequence_fun`, the given function will receive the
  counter and then you can transform in anything you want.

  ## Examples
      iex> ExZample.create_sequence(:my_app, :user_id)
      ...> ExZample.ex_zample(%{ex_zample_scope: :my_app})
      ...> ExZample.sequence(:user_id)
      1

      iex> ExZample.create_sequence(:user_id, &("user_" <> to_string(&1)))
      ...> Enum.map(1..3, fn _ -> ExZample.sequence(:user_id) end)
      ["user_1", "user_2", "user_3"]
  """
  @spec create_sequence(scope_or_name :: atom, sequence_fun_or_name :: sequence_fun | atom) :: :ok
  def create_sequence(scope_or_name, sequence_fun_or_name)

  def create_sequence(name, sequence_fun)
      when is_atom(name) and is_function(sequence_fun, 1),
      do: create_sequence(:global, name, sequence_fun)

  def create_sequence(scope, name)
      when is_atom(scope) and is_atom(name),
      do: create_sequence(scope, name, & &1)

  @doc """
  Same as `create_sequence/1`, but you can define a different scope and a
  sequence function.

  The `scope` is where where your global counter will lives, useful for umbrella
  apps for example. The given `sequence_fun` will receive the counter and then
  you can transform in anything you want.

  ## Examples
      iex> ExZample.create_sequence(:my_app, :user_id, &("user_" <> to_string(&1)))
      ...> ExZample.ex_zample(%{ex_zample_scope: :my_app})
      ...> Enum.map(1..3, fn _ -> ExZample.sequence(:user_id) end)
      ["user_1", "user_2", "user_3"]
  """
  @spec create_sequence(atom, atom, sequence_fun) :: :ok
  def create_sequence(scope, name, sequence_fun)
      when is_atom(scope) and is_atom(name) and is_function(sequence_fun, 1) do
    params = %{sequence_name: sequence_name(scope, name), sequence_fun: sequence_fun}

    case DynamicSupervisor.start_child(SequenceSupervisor, {Sequence, params}) do
      {:ok, _} ->
        :ok

      {:error, {:already_started, _}} ->
        raise ArgumentError, """
        The sequence #{inspect(name)} in #{inspect(scope)} scope already exists!
        Rename the sequence or add it in a different scope.
        """
    end
  catch
    :exit, {:noproc, _} ->
      raise ArgumentError, """
      Looks like :ex_zample application wasn't started.
      Make sure you have started it in your `test_helper.exs`:
          :ok = Application.ensure_started(:ex_zample)
      """
  end

  @doc """
  Builds a struct with given `factory_or_alias` module.

  If the given factory exports the `c:example/0` function it will use to return
  the struct and its values. Otherwise, if the module is a struct it will use
  its default values.

  If will override the generated data with the given `attrs`.

  ## Examples

      iex> ExZample.build(User)
      %ExZample.User{}

      iex> ExZample.build(Factories.User)
      %ExZample.User{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}

      iex> ExZample.build(:book)
      %ExZample.Book{code: "1321", title: "The Book's Title"}

      iex> ExZample.build(User, age: 45)
      %ExZample.User{age: 45}

      iex> ExZample.build(Factories.User, age: 45)
      %ExZample.User{age: 45, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}

      iex> ExZample.build(:book, code: "007")
      %ExZample.Book{code: "007", title: "The Book's Title"}
  """
  @spec build(factory, Enum.t() | nil) :: struct
  def build(factory_or_alias, attrs \\ nil) when is_atom(factory_or_alias) do
    data = try_factory(factory_or_alias) || try_alias(factory_or_alias)

    if attrs, do: struct!(data, attrs), else: data
  end

  defp try_factory(factory) do
    cond do
      function_exported?(factory, :example, 0) ->
        factory.example()

      function_exported?(factory, :__struct__, 1) ->
        struct!(factory)

      true ->
        nil
    end
  end

  defp try_alias(factory_alias) do
    scope = lookup_scope()
    aliases = get_config(scope)[:aliases] || %{}

    if factory = aliases[factory_alias] do
      inspected_argument = inspect(factory)

      try_factory(factory) ||
        raise ArgumentError,
          message: """
          #{inspected_argument} is not a factory
          If #{inspected_argument} is a module, you need to create a `example/0` function
          If #{inspected_argument} is a alias, you need to register it with `ExZample.add_aliases/1`
          """
    else
      raise ArgumentError,
        message:
          "There's no alias registered for #{inspect(factory_alias)} in #{inspect(scope)} scope"
    end
  end

  defp lookup_scope do
    if scope = Process.get(:ex_zample_scope) do
      scope
    else
      scope = lookup_in_processes(:"$callers") || lookup_in_processes(:"$ancestors") || :global
      # NOTE: Faster future lookups
      Process.put(:ex_zample_scope, scope)
      scope
    end
  end

  defp lookup_in_processes(key),
    do: key |> Process.get() |> List.wrap() |> Enum.find_value(&get_process_scope/1)

  defp get_process_scope(name_or_pid) do
    pid = if is_atom(name_or_pid), do: Process.whereis(name_or_pid), else: name_or_pid
    {:dictionary, dictionary} = Process.info(pid, :dictionary)
    dictionary[:ex_zample_scope]
  end

  @doc """
  Same as `build/2`, but returns a list with where the size is the given
  `count`.

  ## Examples

      iex> ExZample.build_list(3, User)
      [%ExZample.User{}, %ExZample.User{}, %ExZample.User{}]

      iex> ExZample.build_list(3, :book)
      [%ExZample.Book{},%ExZample.Book{}, %ExZample.Book{}]

      iex> ExZample.build_list(3, User, age: 45)
      [%ExZample.User{age: 45}, %ExZample.User{age: 45}, %ExZample.User{age: 45}]

      iex> ExZample.build_list(3, :book, code: "007")
      [%ExZample.Book{code: "007"},%ExZample.Book{code: "007"}, %ExZample.Book{code: "007"}]
  """
  @spec build_list(count :: pos_integer, factory, attrs :: Enum.t() | nil) :: [struct]
  def build_list(count, factory, attrs \\ nil)

  def build_list(0, _factory, _attrs), do: []

  def build_list(count, factory, attrs) when is_greater_than_0(count),
    do: Enum.map(1..count, fn _ -> build(factory, attrs) end)

  @doc """
  Same as `build/2`, but returns a tuple with a pair of structs.

  ## Examples

      iex> ExZample.build_pair(User)
      {%ExZample.User{}, %ExZample.User{}}

      iex> ExZample.build_pair(:book)
      {%ExZample.Book{},%ExZample.Book{}}

      iex> ExZample.build_pair(User, age: 45)
      {%ExZample.User{age: 45}, %ExZample.User{age: 45}}

      iex> ExZample.build_pair(:book, code: "007")
      {%ExZample.Book{code: "007"},%ExZample.Book{code: "007"}}
  """
  @spec build_pair(factory, attrs :: Enum.t() | nil) :: {struct, struct}
  def build_pair(factory, attrs \\ nil), do: {build(factory, attrs), build(factory, attrs)}

  @doc """
  Utiliy function that you can define the scope that `ExZample` will look
  for the aliases. If no scope is defined, `:global` is the default
  scope.

  This function works well with `setup/1` callback of `ExUnit` and `@tags`.
  For example:

      defmodule MyTest do
        use ExUnit.Case
        import ExZample

        @moduletag %{ex_zample_scope: :my_app}

        setup :ex_zample

        test "returns a user" do
          assert %User{} == build(:user)
        end
      end

  In the example above, `ExZample` will look for a factory registered in alias
  `:user` in the `:my_app` scope.
  """
  @spec ex_zample(map) :: :ok
  def ex_zample(scope) when is_map(scope) do
    if ex_zample_scope = scope[:ex_zample_scope] do
      Process.put(:ex_zample_scope, ex_zample_scope)
    else
      Process.put(:ex_zample_scope, :global)
    end

    :ok
  end

  @doc """
  Returns the current counter registered in the given sequence `name`.

  ## Examples
      iex> ExZample.create_sequence(:user_id, &("user_" <> to_string(&1)))
      ...> ExZample.sequence(:user_id)
      "user_1"
  """
  @spec sequence(atom) :: term
  def sequence(name) when is_atom(name) do
    lookup_scope()
    |> sequence_name(name)
    |> Sequence.next()
  catch
    :exit, {:noproc, _} ->
      scope = lookup_scope()

      raise ArgumentError, """
      The sequence #{inspect(name)} doesn't exist in the current #{inspect(scope)} scope.
      Make sure your created a sequence using `ExZample.create_sequence/1`.
      """
  end

  @doc """
  Same as `sequence/1`, but returns a list of where the number is determined by
  the given `count`.

  ## Examples
      iex> ExZample.create_sequence(:user_id, &("user_" <> to_string(&1)))
      ...> ExZample.sequence_list(3, :user_id)
      ["user_1", "user_2", "user_3"]
  """
  @spec sequence_list(pos_integer, atom) :: [term]
  def sequence_list(0, _name), do: []

  def sequence_list(count, name) when is_greater_than_0(count),
    do: Enum.map(1..count, fn _ -> sequence(name) end)

  @doc """
  Same as `sequence/1`, but returns a pair of sequence items.

  ## Examples
      iex> ExZample.create_sequence(:user_id, &("user_" <> to_string(&1)))
      ...> ExZample.sequence_pair(:user_id)
      {"user_1", "user_2"}
  """
  @spec sequence_pair(atom) :: {term, term}
  def sequence_pair(name), do: {sequence(name), sequence(name)}

  defp get_config(scope), do: Application.get_env(:ex_zample, scope) || %{}

  defp put_config(scope, config), do: Application.put_env(:ex_zample, scope, config)

  defp sequence_name(scope, name), do: "#{scope}.#{name}"
end