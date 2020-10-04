defmodule ExZample do
  @moduledoc """
  ExZample is a factory library based on Elixir behaviours.
  """

  alias ExZample.{Sequence, SequenceSupervisor}

  import ExZample.Since

  @doc """
  Invoked every time you build your data using `ExZample` module.

  You need to return a struct with example values.

  This callback is optional when the module given is a struct. It will use
  the struct default values if no callback is given.
  """
  since("0.1.0")
  @callback example() :: struct

  @doc """
  Same as `c:example/0`, but here you have the full control in how will build
  your struct given the attributes.

  The keyword list given in functions like `build/2` are transformed in map
  for your convenience and you need to return a struct.

  You can have two scenarios when using this callback:

  1. If you define `example/0` and `example/1` in same factory, `example/0` will
     be prefered when you use `build/1`. The `example/1` will preferend if you
     use with `build/2`.

  2. If you only implement `example/1` and use `build/1`, your callback will
     invoked with an empty map.

  This callback is optional.
  """
  since("0.5.0")
  @callback example(attrs :: map) :: struct

  @doc """
  Invoked every time you insert your data using `ExZample` module.

  You need to return the Ecto `Repo` module that ExZample should use
  to insert records in database

  This callback is optional if the goal is to use only in memory.
  """
  since("0.10.0")
  @callback ecto_repo :: module

  @type factory :: module
  @type sequence_fun :: (pos_integer -> term)

  @optional_callbacks example: 0, example: 1, ecto_repo: 0

  defguardp is_greater_than_0(term) when is_integer(term) and term > 0

  @doc false
  since("0.3.0")
  @deprecated "Use config_aliases/1 instead"
  def add_aliases(aliases), do: config_aliases(aliases)

  @doc false
  since("0.3.0")
  @deprecated "Use config_aliases/2 instead"
  def add_aliases(scope, aliases), do: config_aliases(scope, aliases)

  @doc """
  Creates aliases for your factories to simplify the build calls.

  A `aliases` should be a map with atom keys and values as `factory` compatible
  modules. If you call with repeated keys this function will fail. This function
  is ideal to be called once, for example in your `test_helper.ex` file.

  ## Examples
      iex> ExZample.config_aliases(%{user: UserFactory})
      ...> ExZample.build(:user)
      %User{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}
  """
  since("0.4.0")
  @spec config_aliases(%{required(atom) => factory}) :: :ok
  def config_aliases(aliases) when is_map(aliases), do: config_aliases(:global, aliases)

  @doc """
  Same as `config_aliases/1`, but you can define a different scope.

  This function is specially useful for umbrella apps where each app can define
  their factories without leaking any aliases to other apps. You can enforce the
  current scope with `ex_zample/1`.

  ## Examples
      iex> ExZample.config_aliases(:my_app, %{user: UserFactory})
      ...> ExZample.ex_zample(%{ex_zample_scope: :my_app})
      ...> ExZample.build(:user)
      %User{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}
  """
  since("0.4.0")
  @spec config_aliases(atom, %{required(atom) => factory}) :: :ok
  def config_aliases(scope, aliases) when is_map(aliases) do
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
      iex> ExZample.create_sequence(:customer_id)
      ...> Enum.map(1..10, fn _ -> ExZample.sequence(:customer_id) end)
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  """
  since("0.4.0")
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
      iex> ExZample.create_sequence(:my_app, :customer_id)
      ...> ExZample.ex_zample(%{ex_zample_scope: :my_app})
      ...> ExZample.sequence(:customer_id)
      1

      iex> ExZample.create_sequence(:customer_id, &("customer_" <> to_string(&1)))
      ...> Enum.map(1..3, fn _ -> ExZample.sequence(:customer_id) end)
      ["customer_1", "customer_2", "customer_3"]
  """
  since("0.4.0")
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
      iex> ExZample.create_sequence(:my_app, :customer_id, &("customer_" <> to_string(&1)))
      ...> ExZample.ex_zample(%{ex_zample_scope: :my_app})
      ...> Enum.map(1..3, fn _ -> ExZample.sequence(:customer_id) end)
      ["customer_1", "customer_2", "customer_3"]
  """
  since("0.4.0")
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

      iex> ExZample.build(UserFactory)
      %ExZample.User{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}

      iex> ExZample.build(:book)
      %ExZample.Book{code: "1321", title: "The Book's Title"}

      iex> ExZample.build(User, age: 45)
      %ExZample.User{age: 45}

      iex> ExZample.build(UserFactory, age: 45)
      %ExZample.User{age: 45, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}

      iex> ExZample.build(:book, code: "007")
      %ExZample.Book{code: "007", title: "The Book's Title"}
  """
  since("0.1.0")
  @spec build(factory, Enum.t() | nil) :: struct
  def build(factory_or_alias, attrs \\ nil) when is_atom(factory_or_alias),
    do: try_factory(factory_or_alias, attrs) || try_alias(factory_or_alias, attrs)

  defp try_factory(factory, nil) do
    cond do
      function_exported?(factory, :example, 0) ->
        factory.example()

      function_exported?(factory, :example, 1) ->
        factory.example(%{})

      function_exported?(factory, :__struct__, 1) ->
        struct!(factory)

      true ->
        nil
    end
  end

  defp try_factory(factory, enum) do
    cond do
      function_exported?(factory, :example, 1) ->
        enum
        |> Map.new()
        |> factory.example()

      function_exported?(factory, :example, 0) ->
        struct!(factory.example(), enum)

      function_exported?(factory, :__struct__, 1) ->
        struct!(factory, enum)

      true ->
        nil
    end
  end

  defp try_alias(factory_alias, attrs) do
    scope = lookup_scope()
    aliases = get_config(scope)[:aliases] || %{}

    if factory = aliases[factory_alias] do
      inspected_argument = inspect(factory)

      try_factory(factory, attrs) ||
        raise ArgumentError,
          message: """
          #{inspected_argument} is not a factory
          You need to create a `example/0` function
          """
    else
      inspected_argument = inspect(factory_alias)

      raise ArgumentError,
        message: """
        #{inspected_argument} is not a factory in #{inspect(scope)} scope
        If #{inspected_argument} is a module, you need to create a `example/0` function
        If #{inspected_argument} is a alias, you need to register it with `ExZample.config_aliases/1`
        """
    end
  end

  defp lookup_scope, do: lookup_in_processes_and_set(:ex_zample_scope, :global)

  defp lookup_in_processes_and_set(key, default) do
    if value = Process.get(key) do
      value
    else
      value =
        lookup_in_processes(key, :"$callers") || lookup_in_processes(key, :"$ancestors") ||
          default

      # NOTE: Faster future lookups
      Process.put(key, value)
      value
    end
  end

  defp lookup_in_processes(key, process),
    do: process |> Process.get() |> List.wrap() |> Enum.find_value(&get_process_key(key, &1))

  defp get_process_key(key, name_or_pid) do
    pid = if is_atom(name_or_pid), do: Process.whereis(name_or_pid), else: name_or_pid
    {:dictionary, dictionary} = Process.info(pid, :dictionary)
    dictionary[key]
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
  since("0.2.0")
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
  since("0.2.0")
  @spec build_pair(factory, attrs :: Enum.t() | nil) :: {struct, struct}
  def build_pair(factory, attrs \\ nil), do: {build(factory, attrs), build(factory, attrs)}

  @doc """
  Builds a map with given `factory_or_alias` module. Has the same mechanism of
  `build/2`.

  ## Examples

      iex> ExZample.map_for(User)
      %{age: nil, email: nil, first_name: nil, id: nil, last_name: nil}

      iex> ExZample.map_for(UserFactory)
      %{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}

      iex> ExZample.map_for(:book)
      %{code: "1321", title: "The Book's Title"}

      iex> ExZample.map_for(User, age: 45)
      %{age: 45, email: nil, first_name: nil, id: nil, last_name: nil}

      iex> ExZample.map_for(UserFactory, age: 45)
      %{age: 45, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}

      iex> ExZample.map_for(:book, code: "007")
      %{code: "007", title: "The Book's Title"}
  """
  since("0.8.0")
  @spec map_for(factory, Enum.t() | nil) :: map
  def map_for(factory, attributes \\ nil), do: factory |> build(attributes) |> to_map()

  defp to_map(map) when is_map(map),
    do: for({k, v} <- Map.from_struct(map), into: %{}, do: {k, to_map(v)})

  defp to_map(list) when is_list(list),
    do: Enum.map(list, &to_map/1)

  defp to_map(item), do: item

  @doc """
  Same as `map_for/2`, but returns a list with where the size is the given
  `count`.

  ## Examples

      iex> ExZample.map_list_for(3, User)
      [%{age: nil, email: nil, first_name: nil, id: nil, last_name: nil},
      %{age: nil, email: nil, first_name: nil, id: nil, last_name: nil},
      %{age: nil, email: nil, first_name: nil, id: nil, last_name: nil}]

      iex> ExZample.map_list_for(3, :book)
      [%{code: "1321", title: "The Book's Title"},
      %{code: "1321", title: "The Book's Title"},
      %{code: "1321", title: "The Book's Title"}]

      iex> ExZample.map_list_for(3, User, age: 45)
      [%{age: 45, email: nil, first_name: nil, id: nil, last_name: nil},
      %{age: 45, email: nil, first_name: nil, id: nil, last_name: nil},
      %{age: 45, email: nil, first_name: nil, id: nil, last_name: nil}]

      iex> ExZample.map_list_for(3, :book, code: "007")
      [%{code: "007", title: "The Book's Title"},
      %{code: "007", title: "The Book's Title"},
      %{code: "007", title: "The Book's Title"}]
  """
  since("0.8.0")
  @spec map_list_for(count :: pos_integer, factory, attrs :: Enum.t() | nil) :: [struct]
  def map_list_for(count, factory, attrs \\ nil)

  def map_list_for(0, _factory, _attrs), do: []

  def map_list_for(count, factory, attrs) when is_greater_than_0(count),
    do: Enum.map(1..count, fn _ -> map_for(factory, attrs) end)

  @doc """
  Same as `map_for/2`, but returns a tuple with a pair of maps.

  ## Examples

      iex> ExZample.map_pair_for(User)
      {%{age: nil, email: nil, first_name: nil, id: nil, last_name: nil},
      %{age: nil, email: nil, first_name: nil, id: nil, last_name: nil}}

      iex> ExZample.map_pair_for(:book)
      {%{code: "1321", title: "The Book's Title"},
      %{code: "1321", title: "The Book's Title"}}

      iex> ExZample.map_pair_for(User, age: 45)
      {%{age: 45, email: nil, first_name: nil, id: nil, last_name: nil},
      %{age: 45, email: nil, first_name: nil, id: nil, last_name: nil}}

      iex> ExZample.map_pair_for(:book, code: "007")
      {%{code: "007", title: "The Book's Title"},
      %{code: "007", title: "The Book's Title"}}
  """
  since("0.8.0")
  @spec map_pair_for(factory, attrs :: Enum.t() | nil) :: {struct, struct}
  def map_pair_for(factory, attrs \\ nil), do: {map_for(factory, attrs), map_for(factory, attrs)}

  @doc """
  Builds a map with string keys given `factory_or_alias` module. Has the same mechanism of
  `build/2`. Useful to simulate request parameters in a plug or phoenix
  controller.

  ## Examples

      iex> ExZample.params_for(User)
      %{"age" => nil, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil}

      iex> ExZample.params_for(UserFactory)
      %{"age" => 21, "email" => "test@test.test", "first_name" => "First Name", "id" => 1, "last_name" => "Last Name"}

      iex> ExZample.params_for(:book)
      %{"code" => "1321", "title" => "The Book's Title"}

      iex> ExZample.params_for(User, age: 45)
      %{"age" => 45, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil}

      iex> ExZample.params_for(UserFactory, age: 45)
      %{"age" => 45, "email" => "test@test.test", "first_name" => "First Name", "id" => 1, "last_name" => "Last Name"}

      iex> ExZample.params_for(:book, code: "007")
      %{"code" => "007", "title" => "The Book's Title"}
  """
  since("0.9.0")
  @spec params_for(factory, Enum.t() | nil) :: map
  def params_for(factory, attributes \\ nil), do: factory |> build(attributes) |> to_str_map()

  defp to_str_map(map) when is_map(map),
    do: for({k, v} <- Map.from_struct(map), into: %{}, do: {to_string(k), to_str_map(v)})

  defp to_str_map(list) when is_list(list),
    do: Enum.map(list, &to_str_map/1)

  defp to_str_map(item), do: item

  @doc """
  Same as `params_for/2`, but returns a list with where the size is the given
  `count`.

  ## Examples

      iex> ExZample.params_list_for(3, User)
      [%{"age" => nil, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil},
      %{"age" => nil, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil},
      %{"age" => nil, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil}]

      iex> ExZample.params_list_for(3, :book)
      [%{"code" => "1321", "title" => "The Book's Title"},
      %{"code" => "1321", "title" => "The Book's Title"},
      %{"code" => "1321", "title" => "The Book's Title"}]

      iex> ExZample.params_list_for(3, User, age: 45)
      [%{"age" => 45, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil},
      %{"age" => 45, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil},
      %{"age" => 45, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil}]

      iex> ExZample.params_list_for(3, :book, code: "007")
      [%{"code" => "007", "title" => "The Book's Title"},
      %{"code" => "007", "title" => "The Book's Title"},
      %{"code" => "007", "title" => "The Book's Title"}]
  """
  since("0.9.0")
  @spec params_list_for(count :: pos_integer, factory, attrs :: Enum.t() | nil) :: [struct]
  def params_list_for(count, factory, attrs \\ nil)

  def params_list_for(0, _factory, _attrs), do: []

  def params_list_for(count, factory, attrs) when is_greater_than_0(count),
    do: Enum.map(1..count, fn _ -> params_for(factory, attrs) end)

  @doc """
  Same as `params_for/2`, but returns a tuple with a pair of maps.

  ## Examples

      iex> ExZample.params_pair_for(User)
      {%{"age" => nil, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil},
      %{"age" => nil, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil}}

      iex> ExZample.params_pair_for(:book)
      {%{"code" => "1321", "title" => "The Book's Title"},
      %{"code" => "1321", "title" => "The Book's Title"}}

      iex> ExZample.params_pair_for(User, age: 45)
      {%{"age" => 45, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil},
      %{"age" => 45, "email" => nil, "first_name" => nil, "id" => nil, "last_name" => nil}}

      iex> ExZample.params_pair_for(:book, code: "007")
      {%{"code" => "007", "title" => "The Book's Title"},
      %{"code" => "007", "title" => "The Book's Title"}}
  """
  since("0.9.0")
  @spec params_pair_for(factory, attrs :: Enum.t() | nil) :: {struct, struct}
  def params_pair_for(factory, attrs \\ nil),
    do: {params_for(factory, attrs), params_for(factory, attrs)}

  @doc """
  Utiliy function that you can define severial settings that `ExZample` will look
  for before executing their functions.

  ## Options

    * `:ex_zample_scope`, the scope that ExZample should look up for aliases. If no
    scope is defined, `:global` is the default scope.
    * `:ex_zample_ecto_repo`, the Ecto repo that ExZample should use to run their insert
    functions.

  This function works well with `setup/1` callback of `ExUnit` and `@tags`.
  For example:

      defmodule MyTest do
        use ExUnit.Case
        import ExZample

        @moduletag ex_zample_scope: :my_app

        setup :ex_zample

        test "returns a user" do
          assert %User{} == build(:user)
        end
      end

  In the example above, `ExZample` will look for a factory registered in alias
  `:user` in the `:my_app` scope.
  """
  since("0.3.0")
  @spec ex_zample(map) :: :ok
  def ex_zample(settings) when is_map(settings) do
    if ex_zample_scope = settings[:ex_zample_scope] do
      Process.put(:ex_zample_scope, ex_zample_scope)
    else
      Process.put(:ex_zample_scope, :global)
    end

    if ecto_repo = settings[:ex_zample_ecto_repo] do
      Process.put(:ex_zample_ecto_repo, ecto_repo)
    end

    :ok
  end

  @doc """
  Returns the current counter registered in the given sequence `name`.

  ## Examples
      iex> ExZample.create_sequence(:customer_id, &("customer_" <> to_string(&1)))
      ...> ExZample.sequence(:customer_id)
      "customer_1"
  """
  since("0.4.0")
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
      iex> ExZample.create_sequence(:customer_id, &("customer_" <> to_string(&1)))
      ...> ExZample.sequence_list(3, :customer_id)
      ["customer_1", "customer_2", "customer_3"]
  """
  since("0.4.0")
  @spec sequence_list(pos_integer, atom) :: [term]
  def sequence_list(0, _name), do: []

  def sequence_list(count, name) when is_greater_than_0(count),
    do: Enum.map(1..count, fn _ -> sequence(name) end)

  @doc """
  Same as `sequence/1`, but returns a pair of sequence items.

  ## Examples
      iex> ExZample.create_sequence(:customer_id, &("customer_" <> to_string(&1)))
      ...> ExZample.sequence_pair(:customer_id)
      {"customer_1", "customer_2"}
  """
  since("0.4.0")
  @spec sequence_pair(atom) :: {term, term}
  def sequence_pair(name), do: {sequence(name), sequence(name)}

  if Code.ensure_loaded?(Ecto.Repo) do
    @doc """
    Inserts in the repository the example built by the `factory_or_alias` module.

    If the given factory exports the `c:repo/0` function it will use it call the
    `insert!` function. Beyond that, it works similar as `build/2`.

    If will override the generated data with the given `attributes`.

    ## Options

      * `ecto_opts`, when given, it will be forwarded to the second argument of
      `Ecto.Repo.insert/2`

    ## Examples

        iex> ExZample.insert(:player)
        %ExZample.RPG.Player{}

        iex> ExZample.insert(:player, email: "testmail")
        %ExZample.RPG.Player{email: "testmail"}
  """
    since("0.10.0")
    @spec insert(factory, Enum.t() | nil) :: struct()
    def insert(factory, attributes \\ nil)

    def insert(factory, attributes) when is_list(attributes) do
      {opts, attributes} = Keyword.split(attributes, [:ecto_opts])
      insert(factory, attributes, opts)
    end

    def insert(factory, attributes), do: insert(factory, attributes, [])

    @doc """
    Same as `insert/2`, but the `attributes` and `opts` are explicit
    separated.

    ## Options

      * `ecto_opts`, when given, it will be forwarded to the second argument of
      `Ecto.Repo.insert/2`

    ## Examples

        iex> ExZample.insert(:player, %{email: "testmail"}, ecto_opts: [prefix: "private"])
        %ExZample.RPG.Player{email: "testmail"}
    """
    since("0.10.0")
    @spec insert(factory, Enum.t() | nil, Keyword.t()) :: struct()
    def insert(factory, attributes, opts) do
      record = build(factory, attributes)
      repo = lookup_in_processes_and_set(:ex_zample_ecto_repo, :not_in_processes)
      repo = if repo == :not_in_processes, do: lookup_repo(factory), else: repo

      repo.insert!(record, Keyword.get(opts, :ecto_opts, []))
    end

    defp lookup_repo(factory) do
      factory_module =
        if function_exported?(factory, :ecto_repo, 0) do
          factory
        else
          scope = lookup_scope()
          aliases = get_config(scope)[:aliases]
          aliases[factory]
        end

      factory_module.ecto_repo() ||
        raise ArgumentError, "Your #{factory_module}.repo/0 should return a ecto Repo module"
    end
  end

  defp get_config(scope), do: Application.get_env(:ex_zample, scope) || %{}

  defp put_config(scope, config),
    do: Application.put_env(:ex_zample, scope, config)

  defp sequence_name(scope, name), do: "#{scope}.#{name}"
end
