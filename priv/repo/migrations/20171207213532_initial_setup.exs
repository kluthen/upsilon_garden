defmodule UpsilonGarden.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string

      timestamps()
    end
    create table(:gardens) do
      add :name, :string
      add :dimension, :integer
      add :user_id, references(:users, on_delete: :delete_all)
      add :context, :map
      add :data, :map
      add :projection, :map

      timestamps()
    end

    create index(:gardens, [:user_id])

    create table(:sources) do
      add :type, :integer
      add :power, :integer
      add :radiance, :integer
      add :garden_id, references(:gardens, on_delete: :delete_all)

      timestamps()
    end

    create table(:events) do
      add :type, :integer
      add :start_date, :utc_datetime
      add :duration, :integer
      add :power, :integer
      add :name, :string
      add :description, :string
      add :garden_id, references(:gardens, on_delete: :delete_all)

      timestamps()
    end

    create index(:events, [:garden_id])

    create table(:components) do
      add :quantity, :integer
      add :composition, :string
      add :source_id, references(:sources, on_delete: :delete_all)
      add :event_id, references(:events, on_delete: :delete_all)

      timestamps()
    end

    create index(:components, [:source_id])
    create index(:components, [:event_id])

    create table(:plants) do
      add :name, :string
      add :data, :map
      add :content, :map
      add :context, :map
      add :segment, :integer
      add :celerity, :integer
      add :garden_id, references(:gardens, on_delete: :delete_all)
      timestamps()
    end

  end
end
