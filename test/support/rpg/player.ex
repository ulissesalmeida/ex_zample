defmodule ExZample.RPG.Class do
  @moduledoc false

  use Ecto.Schema

  schema "classes" do
    field :name, :string
    timestamps()
  end
end

defmodule ExZample.RPG.Player do
  @moduledoc false

  use Ecto.Schema

  schema "players" do
    field :email, :string

    has_many :characters, ExZample.RPG.Character

    timestamps()
  end
end
