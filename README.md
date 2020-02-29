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
    {:ex_zample, "~> 0.0.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_zample](https://hexdocs.pm/ex_zample).

## Quick Start

You can build any struct by passing the struct module:

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

If you don't want to mix your test data with your app code, you can define the
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

## Why not other factories libraries?

Right now you shouldn't change for this one. The other factories libraries has
much more features.

However, when your codebase starts to get bigger, it's nice to have a way to split up
your factories files in multiple files. Also, it's important when the errors
should be explicit and easy to reason about.

Most of other Elixir libraries relies on DLS with macro code, and you need to write
macros to split up your factories files. When you get some run time error in
your test, it's very hard to locate where is the real problem.

This library approach is to rely on vanilla Elixir modules and contracts based on
Elixir behaviours. No need to use any macro. The purpose for any macro that can shows up here
will be for syntax sugar, not part of the main functionality.

## Do I really need a factory library?

Probably not, you can define your own modules to return example structs and
insert them with your repo module. However, a factory library can give you some
convenient functions for you don't need to reinvent the wheel.  
