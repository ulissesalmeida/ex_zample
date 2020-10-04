defmodule ExZample.Test do
  use ExUnit.Case, async: true

  alias ExZample.{
    Book,
    User,
    UserWithDefaults,
    UserWithDefaultsAndExample
  }

  alias ExZample.Factories.UserFactory

  require Book

  require UserFactory

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

  doctest ExZample,
    except: [insert: 2, insert: 3, insert_pair: 2, insert_pair: 3, insert_list: 3, insert_list: 4]

  describe "config_aliases/1" do
    import ExZample, only: [config_aliases: 1]

    test "registers aliases in global namespace by default" do
      aliases = %{user: UserFactory, default_struct: UserWithDefaults}

      assert :ok = config_aliases(aliases)

      assert aliases = Application.get_env(:ex_zample, :global)
    end

    test "fails to override the aliases" do
      inital_aliases = %{user: UserFactory, default_struct: UserWithDefaults}
      updated_aliases = %{user: UserWithDefaultsAndExample, default_struct: UserWithDefaults}

      assert :ok = config_aliases(inital_aliases)
      assert_raise ArgumentError, fn -> config_aliases(updated_aliases) end
    end
  end

  describe "create_sequence/1" do
    import ExZample, only: [create_sequence: 1]

    test "registers a sequence to the global scope" do
      assert :ok = create_sequence(:customer_id)
    end

    test "fails to overridden a sequence" do
      assert :ok = create_sequence(:customer_id)
      assert_raise ArgumentError, fn -> create_sequence(:customer_id) end
    end
  end

  describe "create_sequence/2" do
    import ExZample, only: [create_sequence: 2]

    test "registers a sequence with given function to the global scope" do
      assert :ok = create_sequence(:customer_id, fn i -> "user_#{i}" end)
    end

    test "fails to overridden a sequence" do
      assert :ok = create_sequence(:customer_id, fn i -> "user_#{i}" end)

      assert_raise ArgumentError, fn ->
        create_sequence(:customer_id, fn i -> "abilide_#{i}" end)
      end
    end
  end

  describe "create_sequence/3" do
    import ExZample, only: [create_sequence: 3]

    test "registers a sequence to given scope" do
      assert :ok = create_sequence(:global, :customer_id, fn i -> "user_#{i}" end)
      assert :ok = create_sequence(:ex_zample, :customer_id, fn i -> "user_#{i}" end)
    end

    test "fails to overridden a sequenc in given scopee" do
      assert :ok = create_sequence(:ex_zample, :customer_id, fn i -> "user_#{i}" end)

      assert_raise ArgumentError, fn ->
        create_sequence(:ex_zample, :customer_id, fn i -> "user_#{i}" end)
      end
    end
  end

  describe "sequence/1" do
    import ExZample, only: [sequence: 1]

    test "runs the sequence in atomic way" do
      ExZample.create_sequence(:customer_id)

      tasks = for _i <- 1..10, do: Task.async(fn -> sequence(:customer_id) end)

      assert tasks |> Enum.map(&Task.await/1) |> Enum.sort() == Enum.to_list(1..10)
    end

    test "runs the sequence in the global scope when there's no scope defined" do
      ExZample.create_sequence(:customer_id, &(&1 * 2))
      ExZample.create_sequence(:ex_zample, :customer_id)

      assert sequence(:customer_id) == 2
    end

    test "runs the sequence in current scope" do
      ExZample.ex_zample(%{ex_zample_scope: :ex_zample})

      ExZample.create_sequence(:customer_id, &(&1 * 2))
      ExZample.create_sequence(:ex_zample, :customer_id)

      assert sequence(:customer_id) == 1
    end

    test "fails if sequence doesn't exist" do
      assert_raise ArgumentError, fn -> sequence(:customer_id) end
    end
  end

  describe "sequence_list/2" do
    import ExZample, only: [sequence_list: 2]

    test "runs the sequence in atomic way" do
      ExZample.create_sequence(:customer_id)

      tasks = for _i <- 1..5, do: Task.async(fn -> sequence_list(3, :customer_id) end)
      generated_items = tasks |> Enum.flat_map(&Task.await/1) |> Enum.sort()

      assert generated_items == Enum.to_list(1..15)
    end

    test "fails if sequence doesn't exist" do
      assert_raise ArgumentError, fn -> sequence_list(3, :customer_id) end
    end
  end

  describe "sequence_pair/1" do
    import ExZample, only: [sequence_pair: 1]

    test "runs the sequence in atomic way" do
      ExZample.create_sequence(:customer_id)

      tasks =
        for _i <- 1..5,
            do:
              Task.async(fn ->
                {a, b} = sequence_pair(:customer_id)
                [a, b]
              end)

      generated_items = tasks |> Enum.flat_map(&Task.await/1) |> Enum.sort()

      assert generated_items == Enum.to_list(1..10)
    end

    test "fails if sequence doesn't exist" do
      assert_raise ArgumentError, fn -> sequence_pair(:customer_id) end
    end
  end
end
