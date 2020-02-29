defmodule ExZampleTest do
  use ExUnit.Case
  doctest ExZample

  test "greets the world" do
    assert ExZample.hello() == :world
  end
end
