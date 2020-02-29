defmodule ExZampleTest do
  use ExUnit.Case

  alias ExZample.{
    Factories,
    User,
    UserWithDefaults,
    UserWithDefaultsAndExample
  }

  require Factories.User

  doctest ExZample

  describe "build/1" do
    import ExZample, only: [build: 1]

    test "uses struct default values" do
      default_struct = %UserWithDefaults{}

      assert default_struct == build(UserWithDefaults)
    end

    test "uses the example values" do
      default_struct = %UserWithDefaultsAndExample{}

      assert default_struct != (user = build(UserWithDefaultsAndExample))

      assert user == %UserWithDefaultsAndExample{
               first_name: "Example First Name",
               last_name: "Example Last Name"
             }
    end

    test "works with structless modules" do
      assert build(Factories.User) == %User{
               age: 21,
               email: "test@test.test",
               first_name: "First Name",
               id: 1,
               last_name: "Last Name"
             }
    end

    test "fails with invalid module" do
      assert_raise ArgumentError, &invalid_module/0
    end
  end

  def invalid_module, do: ExZample.build(__MODULE__)

  describe "build/2" do
    import ExZample, only: [build: 2]

    test "overrides given attributes on struct default values" do
      default_struct = %UserWithDefaults{}

      user = %UserWithDefaults{} = build(UserWithDefaults, first_name: "Overrided First Name")

      assert user.first_name == "Overrided First Name"
      assert user.last_name == default_struct.last_name
    end

    test "overrides given attributes on example values" do
      user =
        %UserWithDefaultsAndExample{} =
        build(UserWithDefaultsAndExample, first_name: "Overrided First Name")

      assert user.first_name == "Overrided First Name"
      assert user.last_name == "Example Last Name"
    end

    test "overrides given attributes on structless modules" do
      user = %User{} = build(Factories.User, first_name: "Overrided First Name", age: 28)

      assert user.first_name == "Overrided First Name"
      assert user.age == 28

      assert user.last_name == "Last Name"
      assert user.email == "test@test.test"
    end

    test "fails with invalid keys" do
      assert_raise KeyError, &access_invalid_key/0
    end
  end

  def access_invalid_key, do: ExZample.build(Factories.User, company: "Test company")
end
