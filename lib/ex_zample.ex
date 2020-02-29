defmodule ExZample do
  @moduledoc """
  ExZample is a factory library based on Elixir behaviours.
  """

  @doc """
  Invoked every time you build your data using `ExZample` module.

  You need to return a struct with example values.

  This callback is optional when the module given is a struct. It will use
  the struct default values if no callback is given.
  """
  @callback example() :: struct

  @type factory :: module

  @optional_callbacks example: 0

  @doc """
  Builds a struct with given `factory` module.

  If the given factory exports the `example/0` function it will use to return
  the struct and its values. Otherwise, if the module is a struct it will use
  its default values.

  ## Examples

      iex> ExZample.build(User)
      %ExZample.User{}

      iex> ExZample.build(Factories.User)
      %ExZample.User{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}
  """
  @spec build(factory) :: struct
  def build(factory) when is_atom(factory) do
    cond do
      function_exported?(factory, :example, 0) -> factory.example()
      function_exported?(factory, :__struct__, 1) -> struct!(factory)
      true -> raise ArgumentError, message: "#{inspect(factory)} is not a factory"
    end
  end

  @doc """
  Same as `build/1`, but overrides the struct values with the given `attrs`.

  ## Examples

      iex> ExZample.build(User, age: 45)
      %ExZample.User{age: 45}

      iex> ExZample.build(Factories.User, age: 45)
      %ExZample.User{age: 45, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}
  """
  @spec build(factory, Enum.t()) :: struct
  def build(factory, attrs) do
    factory
    |> build()
    |> struct!(attrs)
  end
end
