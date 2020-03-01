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

  If will override the generated data with the given `attrs`.

  ## Examples

      iex> ExZample.build(User)
      %ExZample.User{}

      iex> ExZample.build(Factories.User)
      %ExZample.User{age: 21, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}

      iex> ExZample.build(User, age: 45)
      %ExZample.User{age: 45}

      iex> ExZample.build(Factories.User, age: 45)
      %ExZample.User{age: 45, email: "test@test.test", first_name: "First Name", id: 1, last_name: "Last Name"}
  """
  @spec build(factory, Enum.t() | nil) :: struct
  def build(factory, attrs \\ nil) when is_atom(factory) do
    data =
      cond do
        function_exported?(factory, :example, 0) -> factory.example()
        function_exported?(factory, :__struct__, 1) -> struct!(factory)
        true -> raise ArgumentError, message: "#{inspect(factory)} is not a factory"
      end

    if attrs, do: struct!(data, attrs), else: data
  end

  @doc """
  Same as `build/2`, but returns a list with where the size is the given
  `count`.

  ## Examples

      iex> ExZample.build_list(3, User)
      [%ExZample.User{}, %ExZample.User{}, %ExZample.User{}]

      iex> ExZample.build_list(3, User, age: 45)
      [%ExZample.User{age: 45}, %ExZample.User{age: 45}, %ExZample.User{age: 45}]
  """
  @spec build_list(count :: pos_integer, factory, attrs :: Enum.t() | nil) :: [struct]
  def build_list(count, factory, attrs \\ nil)

  def build_list(0, _factory, _attrs), do: []

  def build_list(count, factory, attrs) when is_integer(count) and count > 0 do
    Enum.map(1..count, fn _ -> build(factory, attrs) end)
  end
end
