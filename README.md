# ExZample

[![Hex.pm](https://img.shields.io/hexpm/v/ex_zample)](https://www.hex.pm/packages/ex_zample)
[![CircleCI](https://img.shields.io/circleci/build/github/ulissesalmeida/ex_zample)](https://circleci.com/gh/ulissesalmeida/ex_zample/tree/master)
[![Coveralls](https://img.shields.io/coveralls/github/ulissesalmeida/ex_zample)](https://coveralls.io/github/ulissesalmeida/ex_zample?branch=master)

A scalable error-friendly factories library for your Elixir apps

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_zample` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_zample, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_zample](https://hexdocs.pm/ex_zample).

## Quick Start

You can build any struct by passing a struct module:

```elixir
iex> ExZample.build(User)
%MyApp.User{first_name: nil, age: 21}
```

`ExZample` will automatically use the default values inside of that struct. If
you want to define different values, you need to implement the `example/0`
callback.

```elixir
defmodule MyApp.User do
  @behaviour ExZample
  defstruct first_name: nil, age: 21

  @impl true
  def example do
    %__MODULE__{first_name: "Abili De Bob", age: 12}
  end
end

iex> ExZample.build(MyApp.User)
%MyApp.User{first_name: "Abili De Bob", age: 12}
```

If you want to separate your test data from your app code, you can define the
factory in a different module:

```elixir
defmodule MyApp.User do
  defstruct first_name: nil, age: 21
end

defmodule MyApp.Factories.UserFactory do
  @behaviour ExZample

  alias MyApp.User

  @impl true
  def example do
    %User{first_name: "Abili De Bob", age: 12}
  end
end

iex> alias MyApp.Factories.UserFactory
iex> ExZample.build(UserFactory)
%MyApp.User{first_name: "Abili De Bob", age: 12}
```

## Using aliases

If you want to use a nickname for your factories, you can register aliases.
For example, in your `test_helper.ex` you can call `ExZample.add_aliases/1`.

```elixir
# in your test_helper.exs
ExZample.add_aliases(%{user: UserFactory})

# in your app_test.exs
test "activates an user" do
  user = ExZample.build(:user)

  assert :ok == MyApp.active_user(user)
end
```

### Aliases and umbrella apps

If you want to avoid the factories leaking through different apps in your
umbrella, you can add aliases under a scope.

```elixir
# in apps/myapp_a/test/test_helper.ex
ExZample.add_aliases(:myapp_a, %{user: UserFactory})
```

Then, you can use `ExZample.ex_zample/1` to narrow the scope of aliases
lookups during in your tests. It fits well with ExUnit `@tags` and `setup/1`
callbacks. For example, if you are working in a Phoenix app, you can put general
scope enforcement in your `test/support/data_case.ex` file:

```elixir
defmodule MyApp.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      # Tells `ExZample` which scope you want to look up for your aliases
      @moduletag ex_zample_scope: :myapp

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      # import ExZample (optional, import the utility functions like `build/2`)

    end
  end

  # Makes `ExZample` narrow the scope of aliases based on the configured tag
  # If you have imported the `ExZample`, you can do: `setup :ex_zample`
  setup &ExZample.ex_zample/1

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end
end
```

## Building your factories

You can use the `build/2`, `build_pair/2` and `build_list/3` to generate data
without side-effects.

```elixir
iex> ExZample.build(UserFactory, age: 42)
%MyApp.User{first_name: "Abili De Bob", age: 42}

iex> ExZample.build_pair(UserFactory, age: 42)
{%MyApp.User{first_name: "Abili De Bob", age: 42}, %MyApp.User{first_name: "Abili De Bob", age: 42}}

iex> ExZample.build_list(100, UserFactory, age: 42)
[
  %MyApp.User{first_name: "Abili De Bob", age: 42},
  %MyApp.User{first_name: "Abili De Bob", age: 42},
  # ...
]

# or using aliases
iex> ExZample.build(:user, age: 42)
%MyApp.User{first_name: "Abili De Bob", age: 42}

iex> ExZample.build_pair(:user, age: 42)
{%MyApp.User{first_name: "Abili De Bob", age: 42}, %MyApp.User{first_name: "Abili De Bob", age: 42}}

iex> ExZample.build_list(100, :user, age: 42)
[
  %MyApp.User{first_name: "Abili De Bob", age: 42},
  %MyApp.User{first_name: "Abili De Bob", age: 42},
  # ...
]
```

When you pass attributes, it will override the default ones defined in your
factories.

## Inspiration

This library was strongly inspired by:

* [ExMachina](https://github.com/thoughtbot/ex_machina)
* [FactoryBot](https://github.com/thoughtbot/factory_bot)

## Why not other factories libraries?

Right now you shouldn't change for this one. The other factories libraries has
much more features.

However, when your codebase starts to get bigger, it's nice to have a way to split up
your factories files in multiple files. Also, it's important when a error happens, it
should be explicit and easy to reason about.

Most of other Elixir libraries relies on DLS with macro code, and you need to write
macros to split up your factories files. When you get some error in
your factory, it's very hard to locate where is the real problem.

This library approach is to rely on vanilla Elixir modules and contracts based on
Elixir behaviours. No need to use any macro. The purpose for any macro that can shows up here
will be for syntax sugar, not part of the main functionality.

## Do I really need a factory library?

Probably not, you can define your own modules to return example structs and
insert them with your repo module. However, a factory library can give you some
convenient functions for you don't need to reinvent the wheel.
