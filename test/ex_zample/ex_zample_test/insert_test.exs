defmodule ExZample.InsertTest do
  use ExZample.DataCase, async: false

  alias ExZample.RPG.{Attributes, Character, Class, Inventory, Item, Player}

  import Mox

  setup :verify_on_exit!

  unless Version.match?(System.version(), ">= 1.8.0") do
    # NOTE: Old Elixirs need explit allowance for mox
    setup :set_mox_from_context
  end

  setup context do
    :ok = Application.ensure_started(:ex_zample)
    ExZample.ex_zample(context)
  end

  describe "insert/1" do
    import ExZample, only: [insert: 1]

    test "inserts a simple structure" do
      classes_count = fn -> Repo.count(Class) end

      class =
        assert_inc(classes_count,
          by: 1,
          do: fn ->
            assert %Class{} = insert(:class)
          end
        )

      assert class.id
      assert class.name
      assert class.inserted_at
      assert class.updated_at
    end

    test "inserts a structure with belongs_to association" do
      counter = fn -> Repo.count(Character) + Repo.count(Player) end

      character =
        assert_inc(counter,
          by: 2,
          do: fn ->
            assert %Character{} = insert(:character_with_player)
          end
        )

      assert character.id
      assert character.name
      assert character.player
      assert character.player_id
      assert character.inserted_at
      assert character.updated_at

      player = character.player

      assert player.id
      assert player.email
      assert player.inserted_at
      assert player.updated_at
    end

    test "inserts a structure with has_one association" do
      counter = fn -> Repo.count(Character) + Repo.count(Inventory) end

      character =
        assert_inc(counter,
          by: 2,
          do: fn ->
            assert %Character{} = insert(:character)
          end
        )

      assert character.id
      assert character.name
      assert character.inventory
      assert character.inserted_at
      assert character.updated_at

      inventory = character.inventory

      assert inventory.id
      assert inventory.character
      assert inventory.character_id == character.id
      assert inventory.inserted_at
      assert inventory.updated_at
    end

    test "inserts a structure with has_many association" do
      counter = fn -> Repo.count(Player) + Repo.count(Character) end

      player =
        assert_inc(counter,
          by: 4,
          do: fn ->
            assert %Player{} = insert(:player_with_characters)
          end
        )

      assert player.id
      assert player.email
      assert player.characters
      assert player.inserted_at
      assert player.updated_at

      for character <- player.characters do
        assert character.id
        assert character.player
        assert character.player_id == player.id
        assert character.inserted_at
        assert character.updated_at
      end
    end

    test "inserts a structure with many_to_many association" do
      counter = fn -> Repo.count(Character) + Repo.count(Class) end

      character =
        assert_inc(counter,
          by: 4,
          do: fn ->
            assert %Character{} = insert(:character)
          end
        )

      assert character.id
      assert character.name
      assert character.classes
      assert character.inserted_at
      assert character.updated_at

      for class <- character.classes do
        assert class.id
        assert class.inserted_at
        assert class.updated_at
      end
    end

    test "inserts a struct with a embeds_one association" do
      counter = fn -> Repo.count(Character) end

      character =
        assert_inc(counter,
          by: 1,
          do: fn ->
            assert %Character{} = insert(:character)
          end
        )

      assert character.id
      assert character.name
      assert character.inserted_at
      assert character.updated_at

      assert %Attributes{} = attributes = character.attributes
      assert is_integer(attributes.strength)
      assert is_integer(attributes.dexterity)
      assert is_integer(attributes.constitution)
      assert is_integer(attributes.intelligence)
      assert is_integer(attributes.wisdom)
      assert is_integer(attributes.charisma)
    end

    test "inserts a struct with a embeds_many association" do
      counter = fn -> Repo.count(Inventory) end

      inventory =
        assert_inc(counter,
          by: 1,
          do: fn ->
            assert %Inventory{} = insert(:inventory)
          end
        )

      assert inventory.id
      assert inventory.items
      assert inventory.inserted_at
      assert inventory.updated_at

      for item <- inventory.items do
        assert %Item{} = item
        assert item.name
        assert item.quantity
        assert item.weight
      end
    end

    test "inserts with a custom repo defined in factory" do
      expect_custom_repo_called()
      counter = fn -> Repo.count(Player) end

      assert_inc(counter,
        by: 1,
        do: fn ->
          assert %Player{} = insert(:custom_repo_player)
        end
      )
    end

    @tag ex_zample_ecto_repo: ExZample.MockRepo
    test "inserts with a custom repo defined in testunit tag" do
      expect_custom_repo_called()
      counter = fn -> Repo.count(Player) end

      assert_inc(counter,
        by: 1,
        do: fn ->
          assert %Player{} = insert(:player)
        end
      )
    end

    @tag ex_zample_ecto_repo: ExZample.MockRepo
    test "inserts looking up in ancestors processes for the ecto repo" do
      expect_custom_repo_called()
      counter = fn -> Repo.count(Player) end

      assert_inc(counter,
        by: 1,
        do: fn ->
          assert %Player{} =
                   fn -> insert(:player) end
                   |> Task.async()
                   |> Task.await()
        end
      )
    end

    # NOTE: Elixir 1.7 and 1.6 doesn't support $callers, drop their support
    # before release 1.0.0.
    if Version.match?(System.version(), ">= 1.8.0") do
      @tag ex_zample_ecto_repo: ExZample.MockRepo
      test "inserts looking up in caller processes for the ecto repo" do
        pid = self()
        expect_custom_repo_called()

        Task.Supervisor.start_child(ExZample.TestTaskSupervisor, fn ->
          send(pid, {:player, insert(:player)})
        end)

        assert_receive {:player, %Player{}}
      end
    end
  end

  describe "insert/2" do
    import ExZample, only: [insert: 2]

    test "overrides the given attributes" do
      assert %Player{email: "myemail"} = insert(:player, email: "myemail")
      assert %Player{email: "myemail2"} = insert(:player, %{email: "myemail2"})
    end

    @tag ex_zample_ecto_repo: ExZample.MockRepo
    test "forwards ecto_opts" do
      opts = [prefix: nil]

      expect(ExZample.MockRepo, :insert!, fn args, ^opts -> ExZample.Repo.insert!(args, opts) end)

      assert %Player{email: "myemail"} = insert(:player, email: "myemail", ecto_opts: opts)
    end
  end

  describe "insert/3" do
    import ExZample, only: [insert: 3]

    test "overrides the given attributes" do
      assert %Player{email: "myemail"} = insert(:player, [email: "myemail"], [])
      assert %Player{email: "myemail2"} = insert(:player, %{email: "myemail2"}, [])
    end

    @tag ex_zample_ecto_repo: ExZample.MockRepo
    test "forwards ecto opts" do
      opts = [prefix: nil]

      expect(ExZample.MockRepo, :insert!, fn args, ^opts -> ExZample.Repo.insert!(args, opts) end)

      assert %Player{email: "myemail"} = insert(:player, [email: "myemail"], ecto_opts: opts)
    end
  end

  describe "insert_pair/1" do
    import ExZample, only: [insert_pair: 1]

    test "inserts two records" do
      counter = fn -> Repo.count(Player) end

      assert_inc(counter,
        by: 2,
        do: fn ->
          assert {%Player{}, %Player{}} = insert_pair(:player)
        end
      )
    end
  end

  describe "insert_pair/2" do
    import ExZample, only: [insert_pair: 2]

    test "overrides the given attributes" do
      counter = fn -> Repo.count(Character) end

      {character_a, character_b} =
        assert_inc(counter,
          by: 2,
          do: fn ->
            assert {%Character{}, %Character{}} = insert_pair(:character, name: "Abili")
          end
        )

      assert character_a.name == "Abili"
      assert character_b.name == "Abili"
    end

    @tag ex_zample_ecto_repo: ExZample.MockRepo
    test "forwards ecto opts" do
      opts = [prefix: nil]
      counter = fn -> Repo.count(Character) end

      expect(ExZample.MockRepo, :insert!, 2, fn args, ^opts ->
        ExZample.Repo.insert!(args, opts)
      end)

      {character_a, character_b} =
        assert_inc(counter,
          by: 2,
          do: fn ->
            assert {%Character{}, %Character{}} =
                     insert_pair(:character, name: "Abili", ecto_opts: opts)
          end
        )

      assert character_a.name == "Abili"
      assert character_b.name == "Abili"
    end
  end

  describe "insert_pair/3" do
    import ExZample, only: [insert_pair: 3]

    test "overrides the given attributes" do
      counter = fn -> Repo.count(Character) end

      {character_a, character_b} =
        assert_inc(counter,
          by: 2,
          do: fn ->
            assert {%Character{}, %Character{}} = insert_pair(:character, %{name: "Abili"}, [])
          end
        )

      assert character_a.name == "Abili"
      assert character_b.name == "Abili"
    end

    @tag ex_zample_ecto_repo: ExZample.MockRepo
    test "forwards ecto opts" do
      opts = [prefix: nil]
      counter = fn -> Repo.count(Character) end

      expect(ExZample.MockRepo, :insert!, 2, fn args, ^opts ->
        ExZample.Repo.insert!(args, opts)
      end)

      {character_a, character_b} =
        assert_inc(counter,
          by: 2,
          do: fn ->
            assert {%Character{}, %Character{}} =
                     insert_pair(:character, %{name: "Abili"}, ecto_opts: opts)
          end
        )

      assert character_a.name == "Abili"
      assert character_b.name == "Abili"
    end
  end

  describe "insert_list/2" do
    import ExZample, only: [insert_list: 2]

    test "returns empty list when count is 0" do
      assert [] == insert_list(0, :character)
    end

    test "inserts up to given count" do
      count = Enum.random(1..10)
      counter = fn -> Repo.count(Character) end

      list =
        assert_inc(counter,
          by: count,
          do: fn ->
            insert_list(count, :character)
          end
        )

      assert length(list) == count
      assert Enum.all?(list, &(%Character{} = &1))
    end
  end

  describe "insert_list/3" do
    import ExZample, only: [insert_list: 3]

    test "returns empty list when count is 0" do
      assert [] == insert_list(0, :character, name: "Abili")
    end

    test "overrides the given attributes" do
      counter = fn -> Repo.count(Character) end
      count = Enum.random(1..10)

      list =
        assert_inc(counter,
          by: count,
          do: fn ->
            insert_list(count, :character, name: "Abili")
          end
        )

      assert length(list) == count
      assert Enum.all?(list, &(&1.name == "Abili"))
    end

    @tag ex_zample_ecto_repo: ExZample.MockRepo
    test "forwards ecto opts" do
      opts = [prefix: nil]
      counter = fn -> Repo.count(Character) end
      count = Enum.random(1..10)

      expect(ExZample.MockRepo, :insert!, count, fn args, ^opts ->
        ExZample.Repo.insert!(args, opts)
      end)

      list =
        assert_inc(counter,
          by: count,
          do: fn ->
            insert_list(count, :character, name: "Abili", ecto_opts: opts)
          end
        )

      assert length(list) == count
      assert Enum.all?(list, &(&1.name == "Abili"))
    end
  end

  describe "insert_list/4" do
    import ExZample, only: [insert_list: 4]

    test "returns empty list when count is 0" do
      assert [] == insert_list(0, :character, %{name: "Abili"}, [])
    end

    test "overrides the given attributes" do
      counter = fn -> Repo.count(Character) end
      count = Enum.random(1..10)

      list =
        assert_inc(counter,
          by: count,
          do: fn ->
            insert_list(count, :character, %{name: "Abili"}, [])
          end
        )

      assert length(list) == count
      assert Enum.all?(list, &(&1.name == "Abili"))
    end

    @tag ex_zample_ecto_repo: ExZample.MockRepo
    test "forwards ecto opts" do
      opts = [prefix: nil]
      counter = fn -> Repo.count(Character) end
      count = Enum.random(1..10)

      expect(ExZample.MockRepo, :insert!, count, fn args, ^opts ->
        ExZample.Repo.insert!(args, opts)
      end)

      list =
        assert_inc(counter,
          by: count,
          do: fn ->
            insert_list(count, :character, %{name: "Abili"}, ecto_opts: opts)
          end
        )

      assert length(list) == count
      assert Enum.all?(list, &(&1.name == "Abili"))
    end
  end

  def assert_inc(counter, by: increment, do: fun) do
    initial = counter.()
    result = fun.()
    current = counter.()

    assert initial + increment == current

    result
  end

  def expect_custom_repo_called do
    expect(ExZample.MockRepo, :insert!, fn args, opts -> ExZample.Repo.insert!(args, opts) end)
  end
end
