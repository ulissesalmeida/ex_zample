defmodule ExZample.RPG.Item do
  @moduledoc false

  use Ecto.Schema

  embedded_schema do
    field :name, :string
    field :quantity, :integer
    field :weight, :decimal
  end
end

defmodule ExZample.RPG.Inventory do
  @moduledoc false

  use Ecto.Schema

  schema "inventories" do
    belongs_to :character, ExZample.RPG.Character
    embeds_many :items, ExZample.RPG.Item

    timestamps()
  end
end
