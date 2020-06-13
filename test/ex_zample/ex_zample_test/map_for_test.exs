defmodule ExZample.MapForTest do
  use ExUnit.Case, async: false

  alias ExZample.{
    Book,
    UserWithDefaults,
    UserWithDefaultsAndExample
  }

  alias ExZample.Factories.{
    SocialUserFactory,
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

  describe "map_for/1 when using modules" do
    import ExZample, only: [map_for: 1]

    test "uses struct default values" do
      default_map = %UserWithDefaults{} |> Map.from_struct()

      assert default_map == map_for(UserWithDefaults)
    end

    test "uses the example values" do
      default_map = %UserWithDefaultsAndExample{} |> Map.from_struct()

      assert default_map != (user = map_for(UserWithDefaultsAndExample))

      assert user == %{
               first_name: "Example First Name",
               last_name: "Example Last Name"
             }
    end

    test "uses the example/1, a.k.a full control, callback" do
      assert map_for(UserWithFullControlFactory) == %{
               id: 2,
               first_name: "full-control:first_name",
               last_name: "full-control:last_name",
               age: 3,
               email: "full-control:email"
             }
    end

    test "uses the example/0 callback when both are defined" do
      assert map_for(UserWithFullControlAndExampleFactory) == %{
               id: 777,
               first_name: "Example Full: First Name",
               last_name: "Example Full: Last Name",
               age: 25,
               email: "Example Full: test@test.test"
             }
    end

    test "works with structless modules" do
      assert map_for(UserFactory) == %{
               age: 21,
               email: "test@test.test",
               first_name: "First Name",
               id: 1,
               last_name: "Last Name"
             }
    end

    test "recursively map the structs" do
      assert map_for(SocialUserFactory) == %{
               user: %{
                 age: 21,
                 email: "test@test.test",
                 first_name: "First Name",
                 id: 1,
                 last_name: "Last Name"
               },
               friends: [
                 %{
                   age: 21,
                   email: "test@test.test",
                   first_name: "First Name",
                   id: 1,
                   last_name: "Last Name"
                 },
                 %{
                   age: 21,
                   email: "test@test.test",
                   first_name: "First Name",
                   id: 1,
                   last_name: "Last Name"
                 },
                 %{
                   age: 21,
                   email: "test@test.test",
                   first_name: "First Name",
                   id: 1,
                   last_name: "Last Name"
                 }
               ]
             }
    end

    test "fails with invalid module" do
      assert_raise ArgumentError, fn -> ExZample.map_for(__MODULE__) end
    end
  end

  describe "map_for/1 when using aliases" do
    import ExZample, only: [map_for: 1]

    setup do
      ExZample.ex_zample(%{ex_zample_scope: nil})

      Application.put_env(:ex_zample, :global, nil)
      Application.put_env(:ex_zample, :ex_zample, nil)

      ExZample.config_aliases(:ex_zample, %{user: UserFactory})
      ExZample.config_aliases(%{user: UserWithDefaults})

      :ok
    end

    test "builds using the global scope when there's no scope specified" do
      assert %{first_name: "A name", last_name: "Last Name"} == map_for(:user)
    end

    test "builds using the aliases of current scope" do
      ExZample.ex_zample(%{ex_zample_scope: :ex_zample})

      assert %{
               id: 1,
               age: 21,
               email: "test@test.test",
               first_name: "First Name",
               last_name: "Last Name"
             } == map_for(:user)
    end

    test "builds looking up for the current scope" do
      ExZample.ex_zample(%{ex_zample_scope: :ex_zample})

      assert %{
               id: 1,
               age: 21,
               email: "test@test.test",
               first_name: "First Name",
               last_name: "Last Name"
             } ==
               fn -> map_for(:user) end
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
        send(pid, {:user, map_for(:user)})
      end)

      assert_receive {:user,
                      %{
                        id: 1,
                        age: 21,
                        email: "test@test.test",
                        first_name: "First Name",
                        last_name: "Last Name"
                      }}
    end

    test "fails with unregistered alias" do
      assert_raise ArgumentError, fn -> map_for(:unregistered_alias) end
    end
  end

  describe "map_for/2" do
    import ExZample, only: [map_for: 2]

    test "overrides given attributes on struct default values" do
      default_struct = %UserWithDefaults{}

      user = map_for(UserWithDefaults, first_name: "Overrided First Name")

      assert user.first_name == "Overrided First Name"
      assert user.last_name == default_struct.last_name
    end

    test "overrides given attributes on example values" do
      user = map_for(UserWithDefaultsAndExample, first_name: "Overrided First Name")

      assert user.first_name == "Overrided First Name"
      assert user.last_name == "Example Last Name"
    end

    test "overrides given attributes on structless modules" do
      user = map_for(UserFactory, first_name: "Overrided First Name", age: 28)

      assert user.first_name == "Overrided First Name"
      assert user.age == 28

      assert user.last_name == "Last Name"
      assert user.email == "test@test.test"
    end

    test "uses the example/1, a.k.a full control, callback" do
      assert map_for(UserWithFullControlFactory, first_name: "overridden", id: 3) ==
               %{
                 id: 6,
                 first_name: "full-control:overridden",
                 last_name: "full-control:last_name",
                 age: 3,
                 email: "full-control:email"
               }
    end

    test "uses the example/1 callback when both are defined" do
      assert map_for(UserWithFullControlAndExampleFactory, last_name: "overridden", age: 3) ==
               %{
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

  def access_invalid_key, do: ExZample.map_for(UserFactory, company: "Test company")

  describe "map_list_for/2" do
    import ExZample, only: [map_list_for: 2]

    test "returns empty list when count is 0" do
      assert [] == map_list_for(0, UserWithDefaults)
    end

    test "builds up to given count" do
      default_map = Map.from_struct(%UserWithDefaults{})
      count = Enum.random(1..100)

      list = map_list_for(count, UserWithDefaults)

      assert length(list) == count
      assert Enum.all?(list, &(&1 == default_map))
    end

    test "uses struct default values" do
      default_map = Map.from_struct(%UserWithDefaults{})

      assert [default_map] == map_list_for(1, UserWithDefaults)
    end

    test "uses the example values" do
      default_map = Map.from_struct(%UserWithDefaultsAndExample{})

      assert [user] = map_list_for(1, UserWithDefaultsAndExample)

      assert default_map != user

      assert user == %{
               first_name: "Example First Name",
               last_name: "Example Last Name"
             }
    end

    test "works with structless modules" do
      assert [
               %{
                 age: 21,
                 email: "test@test.test",
                 first_name: "First Name",
                 id: 1,
                 last_name: "Last Name"
               }
             ] = map_list_for(1, UserFactory)
    end
  end

  describe "map_list_for/3" do
    import ExZample, only: [map_list_for: 3]

    test "returns empty list when count is 0" do
      assert [] == map_list_for(0, UserWithDefaults, first_name: "Test")
    end

    test "builds up to given count" do
      count = Enum.random(1..100)

      list = map_list_for(count, UserWithDefaults, first_name: "Test")

      assert length(list) == count
      assert Enum.all?(list, &(&1.first_name == "Test"))
    end

    test "overrides given attributes on struct default values" do
      default_struct = %UserWithDefaults{}

      [user] = map_list_for(1, UserWithDefaults, first_name: "Overrided First Name")

      assert user.first_name == "Overrided First Name"
      assert user.last_name == default_struct.last_name
    end

    test "overrides given attributes on example values" do
      [user] = map_list_for(1, UserWithDefaultsAndExample, first_name: "Overrided First Name")

      assert user.first_name == "Overrided First Name"
      assert user.last_name == "Example Last Name"
    end

    test "overrides given attributes on structless modules" do
      [user] = map_list_for(1, UserFactory, first_name: "Overrided First Name", age: 28)

      assert user.first_name == "Overrided First Name"
      assert user.age == 28

      assert user.last_name == "Last Name"
      assert user.email == "test@test.test"
    end
  end

  describe "map_pair_for/1" do
    import ExZample, only: [map_pair_for: 1]

    test "uses struct default values" do
      default_map = Map.from_struct(%UserWithDefaults{})

      assert {^default_map, ^default_map} = map_pair_for(UserWithDefaults)
    end

    test "uses the example values" do
      default_map = Map.from_struct(%UserWithDefaultsAndExample{})

      assert {user_a, user_b} = map_pair_for(UserWithDefaultsAndExample)

      assert default_map != user_a
      assert default_map != user_b

      assert user_a == %{
               first_name: "Example First Name",
               last_name: "Example Last Name"
             }

      assert user_b == %{
               first_name: "Example First Name",
               last_name: "Example Last Name"
             }
    end

    test "works with structless modules" do
      expected_example = %{
        age: 21,
        email: "test@test.test",
        first_name: "First Name",
        id: 1,
        last_name: "Last Name"
      }

      assert {^expected_example, ^expected_example} = map_pair_for(UserFactory)
    end
  end

  describe "map_pair_for/2" do
    import ExZample, only: [map_pair_for: 2]

    test "overrides given attributes on struct default values" do
      default_map = Map.from_struct(%UserWithDefaults{})

      {user_a, user_b} = map_pair_for(UserWithDefaults, first_name: "Overrided First Name")

      assert user_a.first_name == "Overrided First Name"
      assert user_a.last_name == default_map.last_name

      assert user_b.first_name == "Overrided First Name"
      assert user_b.last_name == default_map.last_name
    end

    test "overrides given attributes on example values" do
      {user_a, user_b} =
        map_pair_for(UserWithDefaultsAndExample, first_name: "Overrided First Name")

      assert user_a.first_name == "Overrided First Name"
      assert user_a.last_name == "Example Last Name"

      assert user_b.first_name == "Overrided First Name"
      assert user_b.last_name == "Example Last Name"
    end

    test "overrides given attributes on structless modules" do
      {user_a, user_b} = map_pair_for(UserFactory, first_name: "Overrided First Name", age: 28)

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
