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

  describe "build_list/2" do
    import ExZample, only: [build_list: 2]

    test "returns empty list when count is 0" do
      assert [] == build_list(0, UserWithDefaults)
    end

    test "builds up to given count" do
      default_struct = %UserWithDefaults{}
      count = Enum.random(1..100)

      list = build_list(count, UserWithDefaults)

      assert length(list) == count
      assert Enum.all?(list, &(&1 == default_struct))
    end

    test "uses struct default values" do
      default_struct = %UserWithDefaults{}

      assert [^default_struct] = build_list(1, UserWithDefaults)
    end

    test "uses the example values" do
      default_struct = %UserWithDefaultsAndExample{}

      assert [user] = build_list(1, UserWithDefaultsAndExample)

      assert default_struct != user

      assert user == %UserWithDefaultsAndExample{
               first_name: "Example First Name",
               last_name: "Example Last Name"
             }
    end

    test "works with structless modules" do
      assert [
               %User{
                 age: 21,
                 email: "test@test.test",
                 first_name: "First Name",
                 id: 1,
                 last_name: "Last Name"
               }
             ] = build_list(1, Factories.User)
    end
  end

  describe "build_list/3" do
    import ExZample, only: [build_list: 3]

    test "returns empty list when count is 0" do
      assert [] == build_list(0, UserWithDefaults, first_name: "Test")
    end

    test "builds up to given count" do
      count = Enum.random(1..100)

      list = build_list(count, UserWithDefaults, first_name: "Test")

      assert length(list) == count
      assert Enum.all?(list, &(&1.first_name == "Test"))
    end

    test "overrides given attributes on struct default values" do
      default_struct = %UserWithDefaults{}

      [%UserWithDefaults{} = user] =
        build_list(1, UserWithDefaults, first_name: "Overrided First Name")

      assert user.first_name == "Overrided First Name"
      assert user.last_name == default_struct.last_name
    end

    test "overrides given attributes on example values" do
      [%UserWithDefaultsAndExample{} = user] =
        build_list(1, UserWithDefaultsAndExample, first_name: "Overrided First Name")

      assert user.first_name == "Overrided First Name"
      assert user.last_name == "Example Last Name"
    end

    test "overrides given attributes on structless modules" do
      [%User{} = user] =
        build_list(1, Factories.User, first_name: "Overrided First Name", age: 28)

      assert user.first_name == "Overrided First Name"
      assert user.age == 28

      assert user.last_name == "Last Name"
      assert user.email == "test@test.test"
    end
  end

  describe "build_pair/1" do
    import ExZample, only: [build_pair: 1]

    test "uses struct default values" do
      default_struct = %UserWithDefaults{}

      assert {^default_struct, ^default_struct} = build_pair(UserWithDefaults)
    end

    test "uses the example values" do
      default_struct = %UserWithDefaultsAndExample{}

      assert {user_a, user_b} = build_pair(UserWithDefaultsAndExample)

      assert default_struct != user_a
      assert default_struct != user_b

      assert user_a == %UserWithDefaultsAndExample{
               first_name: "Example First Name",
               last_name: "Example Last Name"
             }

      assert user_b == %UserWithDefaultsAndExample{
               first_name: "Example First Name",
               last_name: "Example Last Name"
             }
    end

    test "works with structless modules" do
      expected_example = %User{
        age: 21,
        email: "test@test.test",
        first_name: "First Name",
        id: 1,
        last_name: "Last Name"
      }

      assert {^expected_example, ^expected_example} = build_pair(Factories.User)
    end
  end

  describe "build_pair/2" do
    import ExZample, only: [build_pair: 2]

    test "overrides given attributes on struct default values" do
      default_struct = %UserWithDefaults{}

      {%UserWithDefaults{} = user_a, %UserWithDefaults{} = user_b} =
        build_pair(UserWithDefaults, first_name: "Overrided First Name")

      assert user_a.first_name == "Overrided First Name"
      assert user_a.last_name == default_struct.last_name

      assert user_b.first_name == "Overrided First Name"
      assert user_b.last_name == default_struct.last_name
    end

    test "overrides given attributes on example values" do
      {%UserWithDefaultsAndExample{} = user_a, %UserWithDefaultsAndExample{} = user_b} =
        build_pair(UserWithDefaultsAndExample, first_name: "Overrided First Name")

      assert user_a.first_name == "Overrided First Name"
      assert user_a.last_name == "Example Last Name"

      assert user_b.first_name == "Overrided First Name"
      assert user_b.last_name == "Example Last Name"
    end

    test "overrides given attributes on structless modules" do
      {%User{} = user_a, %User{} = user_b} =
        build_pair(Factories.User, first_name: "Overrided First Name", age: 28)

      assert user_a.first_name == "Overrided First Name"
      assert user_a.age == 28
      assert user_a.last_name == "Last Name"
      assert user_a.email == "test@test.test"

      assert user_b.first_name == "Overrided First Name"
      assert user_b.age == 28
      assert user_b.last_name == "Last Name"
      assert user_b.email == "test@test.test"
    end
  end
end
