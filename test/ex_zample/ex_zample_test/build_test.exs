defmodule ExZample.BuildTest do
  use ExUnit.Case, async: false

  alias ExZample.{
    Book,
    User,
    UserWithDefaults,
    UserWithDefaultsAndExample
  }

  alias ExZample.Factories.{
    UserFactory,
    UserWithFullControlAndExampleFactory,
    UserWithFullControlFactory
  }

  require Book

  require UserFactory
  require UserWithFullControlFactory
  require UserWithFullControlAndExampleFactory

  setup do
    :ok = Application.ensure_started(:ex_zample)
    default_env = Application.get_all_env(:ex_zample)

    ExZample.config_aliases(%{book: Book})

    on_exit(fn ->
      Enum.each(default_env, fn {key, value} ->
        Application.put_env(:ex_zample, key, value)
      end)

      Application.stop(:ex_zample)
    end)
  end

  describe "build/1 when using modules" do
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

    test "uses the example/1, a.k.a full control, callback" do
      assert build(UserWithFullControlFactory) == %User{
               id: 2,
               first_name: "full-control:first_name",
               last_name: "full-control:last_name",
               age: 3,
               email: "full-control:email"
             }
    end

    test "uses the example/0 callback when both are defined" do
      assert build(UserWithFullControlAndExampleFactory) == %User{
               id: 777,
               first_name: "Example Full: First Name",
               last_name: "Example Full: Last Name",
               age: 25,
               email: "Example Full: test@test.test"
             }
    end

    test "works with structless modules" do
      assert build(UserFactory) == %User{
               age: 21,
               email: "test@test.test",
               first_name: "First Name",
               id: 1,
               last_name: "Last Name"
             }
    end

    test "fails with invalid module" do
      assert_raise ArgumentError, fn -> ExZample.build(__MODULE__) end
    end
  end

  describe "build/1 when using aliases" do
    import ExZample, only: [build: 1]

    setup do
      ExZample.ex_zample(%{ex_zample_scope: nil})

      Application.put_env(:ex_zample, :global, nil)
      Application.put_env(:ex_zample, :ex_zample, nil)

      ExZample.config_aliases(:ex_zample, %{user: UserFactory})
      ExZample.config_aliases(%{user: UserWithDefaults})

      :ok
    end

    test "builds using the global scope when there's no scope specified" do
      assert %UserWithDefaults{} = build(:user)
    end

    test "builds using the aliases of current scope" do
      ExZample.ex_zample(%{ex_zample_scope: :ex_zample})

      assert %User{id: 1} = build(:user)
    end

    test "builds looking up for the current scope" do
      ExZample.ex_zample(%{ex_zample_scope: :ex_zample})

      assert %User{id: 1} =
               fn -> build(:user) end
               |> Task.async()
               |> Task.await()
    end

    # NOTE: Elixir 1.7 and 1.6 doesn't support $callers, drop their support
    # before release 1.0.0.
    @tag :skip
    test "builds looking up for the caller process" do
      pid = self()

      ExZample.ex_zample(%{ex_zample_scope: :ex_zample})

      Task.Supervisor.start_child(ExZample.TestTaskSupervisor, fn ->
        send(pid, {:user, build(:user)})
      end)

      assert_receive {:user, %User{id: 1}}
    end

    test "fails with unregistered alias" do
      assert_raise ArgumentError, fn -> build(:unregistered_alias) end
    end
  end

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
      user = %User{} = build(UserFactory, first_name: "Overrided First Name", age: 28)

      assert user.first_name == "Overrided First Name"
      assert user.age == 28

      assert user.last_name == "Last Name"
      assert user.email == "test@test.test"
    end

    test "uses the example/1, a.k.a full control, callback" do
      assert build(UserWithFullControlFactory, first_name: "overridden", id: 3) ==
               %User{
                 id: 6,
                 first_name: "full-control:overridden",
                 last_name: "full-control:last_name",
                 age: 3,
                 email: "full-control:email"
               }
    end

    test "uses the example/1 callback when both are defined" do
      assert build(UserWithFullControlAndExampleFactory, last_name: "overridden", age: 3) ==
               %User{
                 id: 2,
                 first_name: "full-control:first_name",
                 last_name: "full-control:overridden",
                 age: 9,
                 email: "full-control:email"
               }
    end

    test "fails with invalid keys" do
      assert_raise KeyError, &access_invalid_key/0
    end
  end

  def access_invalid_key, do: ExZample.build(UserFactory, company: "Test company")

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
             ] = build_list(1, UserFactory)
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
      [%User{} = user] = build_list(1, UserFactory, first_name: "Overrided First Name", age: 28)

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

      assert {^expected_example, ^expected_example} = build_pair(UserFactory)
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
        build_pair(UserFactory, first_name: "Overrided First Name", age: 28)

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
