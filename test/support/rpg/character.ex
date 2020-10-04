defmodule ExZample.RPG.Attributes do
  @moduledoc false

  use Ecto.Schema

  embedded_schema do
    field :strength, :integer
    field :dexterity, :integer
    field :constitution, :integer
    field :intelligence, :integer
    field :wisdom, :integer
    field :charisma, :integer
  end
end

defmodule ExZample.RPG.Character do
  @moduledoc false

  use Ecto.Schema

  schema "characters" do
    field :name, :string

    belongs_to :player, ExZample.RPG.Player

    embeds_one :attributes, ExZample.RPG.Attributes
    many_to_many :classes, ExZample.RPG.Class, join_through: "characters_classes"
    has_one :inventory, ExZample.RPG.Inventory

    timestamps()
  end
end
