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
    {:ex_zample, "~> 0.9.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_zample](https://hexdocs.pm/ex_zample).

## Quick Start

You can build any struct by passing a struct module:

```elixir
ExZample.build(User)
# => %MyApp.User{first_name: nil, age: 21}
```

`ExZample` will automatically use the default values inside of that struct. If
you want to define different values, you can create factories using
`ExZample.DSL`. For example:

```elixir
defmodule MyApp.Factories do
  use ExZample.DSL

  alias ExZample.User

  factory :user do
    example do
      %User{
        id: sequence(:user_id),
        first_name: "Abili De Bob",
        age: 12,
      }
    end
  end

  def_sequence :user_id
end

# Don't forget to start :ex_zample app!
# for example, in your: test_helper.exs
:ok = Application.ensure_started(:ex_zample)
```

Now you can invoke them like this:

```elixir
ExZample.build(:user)
# => %MyApp.User{id: 1, first_name: "Abili De Bob", age: 12}
```

This is the basics of what you need to start using `ExZample`. The later section
of this README we'll dig in details of how this library works.

## ExZample and Ecto

If your application has `ecto` as dependecy, you'll have the `ExZample.insert`
family functions. You need to tell ExZample which module repository it should
use. You can define and specify in many ways, here are some examples:

```elixir
defmodule MyApp.Factories do
  # By default, all factories will use the given `ecto_repo`
  use ExZample.DSL, ecto_repo: MyApp.Repo

  alias ExZample.User

  factory :user do
    example do
      %User{
        first_name: "Abili De Bob",
        age: 12,
      }
    end
  end

  factory :external_user do
    example do
      %User{
        first_name: "External De Bob",
        age: 12,
      }
    end

    # You can specify a repository per factory too. It
    # overrides the default one.
    repo do
      MyApp.OtherRepo
    end
  end
end
```

You can also override the repo by using test tags:

```elixir
setup context do
  ExZample.ex_zample(context)
end

@tag ex_zample_ecto_repo: MyApp.Repo
test "does something" do
  user = ExZample.insert(:user)
end
```

The `ExZample.insert` family functions works simlilar as the
`ExZample.build` ones. You'll can see a further explanation
below.

## Building your factories

You can use the `build/2`, `build_pair/2` and `build_list/3` to generate data
without side-effects.

```elixir
# or using aliases
ExZample.build(:user, age: 42)
# => %MyApp.User{id: 1, first_name: "Abili De Bob", age: 42}

ExZample.build_pair(:user, age: 42)
# => {%MyApp.User{id: 2, first_name: "Abili De Bob", age: 42}, %MyApp.User{id: 3, first_name: "Abili De Bob", age: 42}}

ExZample.build_list(100, :user, age: 42)
# => [
#      %MyApp.User{id: 4, first_name: "Abili De Bob", age: 42},
#      %MyApp.User{id: 5, first_name: "Abili De Bob", age: 42},
#      ...
#   ]

# or using the modules directly
ExZample.build(UserFactory, age: 42)
# => %MyApp.User{id: 106, first_name: "Abili De Bob", age: 42}

ExZample.build_pair(UserFactory, age: 42)
# => {%MyApp.User{id: 107, first_name: "Abili De Bob", age: 42}, %MyApp.User{id: 108, first_name: "Abili De Bob", age: 42}}

ExZample.build_list(100, UserFactory, age: 42)
# => [
#      %MyApp.User{id: 110, first_name: "Abili De Bob", age: 42},
#      %MyApp.User{id: 111, first_name: "Abili De Bob", age: 42},
#      ...
#   ]
```

When you pass attributes, it will override the default ones defined in your
factories.

## Sequences

Sequences are global stateful counters that you can user in your tests. You can define them using DSL like this:

```elixir
defmodule MyApp.Factories do
  use ExZample.DSL

# ...

  def_sequence :order_id
  def_sequence :user_email, return: &"email_#{&1}@test.test"
end
```

Then, in your factories or in your tests you can invoke them using
`ExZample.sequence/1` this:

```elixir
factory :user do
  example do
    %User{
      email: sequence(:user_email),
      name: "Abili de bob"
    }
  end
end

# or in your tests
test "tracks an order" do
  order_id = ExZample.sequence(:order_id)
  # => 1
end
```

You can manually create your sequences after your test suite starts by using
`ExZample.create_sequence`. For example, in your `test_helper.exs`:

```elixir
# test_helper.exs
:ok = Application.ensure_started(:ex_zample)

ExZample.create_sequence(:order_id)
ExZample.create_sequence(:user_email, &"email_#{&1}@test.test")
```

Sequences are `Agent` processes, no matter how many processes tries to get the
next value, the OTP will guarantee it will always generate a different one for
each request.

### ExZample and Umbrella apps

If you want to avoid the factories or sequences leaking through different apps
in your umbrella, you can define them under a scope.

```elixir
# defining factories and sequences
defmodule MyApp.Factories do
  use ExZample.DSL, scope: :app_a

  alias ExZample.User

  factory :user do
    example do
      %User{
        email: sequence(:user_email)
        first_name: "Abili De Bob",
        age: 12,
      }
    end
  end

  sequence :user_email, return: &"user_#{&1}@test.test"
end
```

Then, you can use `ExZample.ex_zample/1` to narrow the scope of lookups
during in your tests. It fits well with ExUnit `@tags` and `setup/1`
callbacks. For example, if you are working in a Phoenix app, you can put general
scope enforcement in your `test/support/data_case.ex` file:

```elixir
defmodule MyApp.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag [
        # Tells `ExZample` which scope you want to look up for your aliases
        ex_zample_scope: :app_a,
        # If didn't defined in factory module the repo, here
        # you can tell `ExZample` which repo you want all tests to use
        ex_zample_ecto_repo: MyAppA.Repo
      ]

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      # (optional, import the utility functions like `build/2`, `sequence/1`)
      import ExZample
    end
  end

  # Makes `ExZample` narrow the scope of aliases based on the configured tag
  # If you have imported the `ExZample`.
  setup :ex_zample

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end
end
```

Using the the configuration above and narrowing the scope you can have stronger
boundary between your Umbrella apps.

## Using structs as factories.

All your module need to do to use the `ExZample` functions is: implement the
the `example/0` or `example/1` callback.

```elixir
defmodule MyApp.User do
  @behaviour ExZample
  defstruct first_name: nil, age: 21

  @impl true
  def example do
    %__MODULE__{first_name: "Abili De Bob", age: 12}
  end
end

# later
ExZample.build(MyApp.User)
# => %MyApp.User{first_name: "Abili De Bob", age: 12}
```

When you implement the `example` callback, any module can be a factory.

## Defining manually your factory modules

If you want to separate your test data from your app code, you can define a
factory in a different module from your struct:

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

# later
alias MyApp.Factories.UserFactory
ExZample.build(UserFactory)
# => %MyApp.User{first_name: "Abili De Bob", age: 12}
```

You can implement the `example/1` callback when you want to have full control
in how your factories are built:

```elixir
@impl true
def example(attrs) do
  age = Map.get(attrs, :age, 12) * 2
  first_name = Map.get(attrs, :first_name, "Abilid") <> " De Bob"

  %User{first_name: first_name, age: age}
end

# later
build(:user, first_name: "Alice")
# => %User{first_name: "Alice De Bob", age: 24}
```

You don't need to type all this boilerplate code if you use the `ExZample.DSL`.
The `Example.DSL` also supports the full control of your factories:

```elixir
factory :user do
  import Map, only: [get: 3]

  example(attrs) do
    %User{
      first_name: attrs |> get(:first_name, " De Bob") |> prefix(),
      age: get(attrs, :age, 12) * 2,
    }
  end

  defp prefix(string), do: "Abilid #{string}"
end
```

As you can see, the body of the `factory` directive works as any Elixir module.
You can import and define helpers functions.

## Manually defining your aliases

If don't want to use the `ExZample.DSL`, you can manually define a nickname for your factories. For example, in your `test_helper.ex`, after starting `ex_zample`, you
can call `ExZample.config_aliases/1`.

```elixir
# in your test_helper.exs

# Don't forget to start :ex_zample app!
:ok = Application.ensure_started(:ex_zample)

# defining manually your aliases
ExZample.config_aliases(%{user: UserFactory})

# later in your app_test.exs
test "activates an user" do
  user = ExZample.build(:user)

  assert :ok == MyApp.active_user(user)
end
```

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
