# frozen_string_literal: true

class SetupTestDb < ::ActiveRecord::Migration::Current
  def up
    IronTrail::DbFunctions.new(connection).install_functions

    create_table :people, id: :bigserial, force: true do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.timestamp :first_acquired_guitar_at
    end

    create_table :guitars, id: :uuid, force: true do |t|
      t.bigint :person_id, null: false
      t.string :description, null: false
    end
  end

  def down
    # no need to implement this
    raise ActiveRecord::IrreversibleMigration
  end
end
