# frozen_string_literal: true

class SetupTestDb < ::ActiveRecord::Migration::Current
  def up
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
      t.date :opening_day
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
