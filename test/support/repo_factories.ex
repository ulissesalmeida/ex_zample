defmodule ExZample.Factories.RPG do
  @moduledoc false

  use ExZample.DSL, ecto_repo: ExZample.Repo

  alias ExZample.RPG.{Attributes, Character, Class, Inventory, Item, Player}

  factory :player do
    example do
      %Player{email: sequence(:player_email)}
    end
  end

  factory :custom_repo_player do
    example do
      build(:player)
    end

    ecto_repo do
      ExZample.MockRepo
    end
  end

  def_sequence :player_email, return: &"player_#{&1}@test.com"

  factory :player_with_characters do
    example do
      %{build(:player) | characters: build_list(3, :character)}
    end
  end

  factory :character do
    example do
      names = ~w(Billy Agatha Cid Sarah Ash Misty Mike Dorah Tupan
      Mikasa Ellen Drizzit Mia)

      %Character{
        name: Enum.random(names),
        inventory: build(:inventory),
        classes: build_list(3, :class),
        attributes: build(:attributes)
      }
    end
  end

  factory :character_with_player do
    example do
      %{build(:character) | player: build(:player)}
    end
  end

  factory :inventory do
    example do
      %Inventory{
        items: build_list(3, :item)
      }
    end
  end

  factory :item do
    example do
      {name, qty, weight} =
        Enum.random([
          {"Rope", 1, 5},
          {"Potion", 3, 1},
          {"Backpack", 1, 1},
          {"Ratio", 10, 1},
          {"Scroll", 5, 0.1},
          {"Piton", 3, 1}
        ])

      %Item{name: name, quantity: qty, weight: weight}
    end
  end

  factory :class do
    example do
      name = sequence(:class_names)

      ExZample.Repo.get_by(Class, name: name) || %Class{name: name}
    end
  end

  def_sequence :class_names,
    return: fn index ->
      class_names = ~w(Barbarian Bard Cleric Druid Fighter Ranger Rogue Sorcerer Warlock Wizard)

      class_names
      |> Stream.cycle()
      |> Enum.at(index)
    end

  factory :attributes do
    example do
      %Attributes{
        strength: old_school_roll(),
        dexterity: old_school_roll(),
        constitution: old_school_roll(),
        intelligence: old_school_roll(),
        wisdom: old_school_roll(),
        charisma: old_school_roll()
      }
    end

    def old_school_roll do
      import Enum, only: [random: 1]
      d6 = 1..6

      random(d6) + random(d6) + random(d6)
    end
  end
end
