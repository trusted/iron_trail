# frozen_string_literal: true

class SetupTestDb < ::ActiveRecord::Migration::Current
  def up
    # When the test database is a pg_duckdb build, install the extension so the
    # suite exercises IronTrail's triggers and query-comment metadata path with
    # pg_duckdb's planner/executor hooks active. Auto-detected via
    # pg_available_extensions so the plain-Postgres CI matrix rows (and any
    # local vanilla Postgres) simply skip it instead of failing.
    if connection.select_value("SELECT 1 FROM pg_available_extensions WHERE name = 'pg_duckdb'")
      execute 'CREATE EXTENSION IF NOT EXISTS pg_duckdb'
      # pg_duckdb's install script pins search_path to "pg_catalog, pg_temp" for
      # the remainder of the enclosing transaction. Migrations run in a single
      # transaction, so without this reset the create_table calls below would
      # try to create their sequences in pg_catalog and fail with
      # "System catalog modifications are currently disallowed".
      execute 'RESET search_path'
    end

    create_table :people, id: :bigserial, force: true do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :favorite_planet
      t.bigint :converted_by_pill_id
      t.bigint :owns_the_hotel
      t.timestamp :first_acquired_guitar_at
    end

    create_table :guitars, id: :uuid, force: true do |t|
      t.bigint :person_id, null: false
      t.string :description, null: false
    end

    create_table :hotels, id: :bigserial, force: true do |t|
      t.string :name
      t.timestamp :hotel_time
      t.timestamptz :time_in_japan
      t.jsonb :room_map
    end

    create_table :guitar_parts, id: :bigserial, force: true do |t|
      t.uuid :guitar_id
      t.string :name

      t.timestamps
    end

    create_table :matrix_pills, id: :bigserial, force: true do |t|
      t.string :type, null: false
      t.integer :pill_size
    end
  end

  def down
    # no need to implement this
    raise ActiveRecord::IrreversibleMigration
  end
end
