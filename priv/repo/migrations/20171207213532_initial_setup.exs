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

      timestamps()
    end

    create index(:gardens, [:user_id])

    create table(:segments) do
      add :position, :integer
      add :active, :boolean
      add :depth, :integer
      add :sunshine, :float
      add :garden_id, references(:gardens, on_delete: :delete_all)

      timestamps()
    end

    create index(:segments, [:garden_id])

    create table(:blocs) do
      add :position, :integer
      add :type, :integer
      add :segment_id, references(:segments, on_delete: :delete_all)

      timestamps()
    end

    create index(:blocs, [:segment_id])

    create table(:sources) do
      add :type, :integer
      add :power, :integer
      add :position, :integer

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
      add :number, :integer
      add :component, :string
      add :bloc_id, references(:blocs, on_delete: :delete_all)
      add :source_id, references(:sources, on_delete: :delete_all)
      add :event_id, references(:events, on_delete: :delete_all)

      timestamps()
    end

    create index(:components, [:bloc_id])
    create index(:components, [:source_id])
    create index(:components, [:event_id])

    create table(:plants) do
      add :name, :string

      timestamps()
    end

    create table(:influences) do
      add :type, :integer
      add :ratio, :float
      add :event_id, references(:events, on_delete: :delete_all)
      add :plant_id, references(:plants, on_delete: :delete_all)
      add :source_id, references(:sources, on_delete: :delete_all)
      add :bloc_id, references(:blocs, on_delete: :delete_all)

      timestamps()
    end

    create index(:influences, [:event_id])
    create index(:influences, [:plant_id])
    create index(:influences, [:source_id])
  end
end
