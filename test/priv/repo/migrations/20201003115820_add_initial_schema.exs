defmodule ExZample.Repo.Migrations.AddInitialSchema do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :email, :string, null: false
      timestamps()
    end

    create unique_index(:players, [:email])

    create table(:characters) do
      add :name, :string, null: false
      add :attributes, :map
      add :player_id, references(:players)
      timestamps()
    end

    create table(:inventories) do
      add :character_id, references(:characters)
      add :items, :map
      timestamps()
    end

    create unique_index(:inventories, [:character_id])

    create table(:classes) do
      add :name, :string, null: false
      timestamps()
    end

    create unique_index(:classes, [:name])

    create table(:characters_classes, primary_key: false) do
      add :character_id, references(:characters), primary_key: true
      add :class_id, references(:classes), primary_key: true
    end

    create unique_index(:characters_classes, [:character_id, :class_id])
  end
end
