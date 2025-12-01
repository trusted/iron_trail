# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IrontrailChangeCallback, iron_trail: true do
  before(:all) do
    # Create a test extension function that logs to a test table
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS extension_test_log (
        id BIGSERIAL PRIMARY KEY,
        change_id BIGINT,
        rec_table TEXT,
        operation TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE OR REPLACE FUNCTION test_extension_function(
        p_change_id BIGINT,
        p_rec_table TEXT,
        p_operation TEXT
      ) RETURNS VOID AS $$
      BEGIN
        INSERT INTO extension_test_log (change_id, rec_table, operation)
        VALUES (p_change_id, p_rec_table, p_operation);
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  after(:all) do
    ActiveRecord::Base.connection.execute(<<~SQL)
      DROP FUNCTION IF EXISTS test_extension_function(BIGINT, TEXT, TEXT);
      DROP TABLE IF EXISTS extension_test_log;
    SQL
  end

  before do
    ActiveRecord::Base.connection.execute('TRUNCATE extension_test_log')
  end

  describe 'extension execution' do
    context 'when extension is enabled' do
      before do
        IrontrailChangeCallback.create!(
          rec_table: 'people',
          function_name: 'test_extension_function',
          enabled: true
        )
      end

      it 'calls the extension function on insert' do
        person = Person.create!(first_name: 'John', last_name: 'Doe')

        logs = ActiveRecord::Base.connection.execute('SELECT * FROM extension_test_log').to_a
        expect(logs.size).to eq(1)
        expect(logs.first['rec_table']).to eq('people')
        expect(logs.first['operation']).to eq('i')

        change = IrontrailChange.where(id: logs.first['change_id']).take
        expect(change.rec_table).to eq('people')
        expect(change.rec_id).to eq(person.id.to_s)
        expect(change.rec_new['first_name']).to eq('John')
        expect(change.rec_new['last_name']).to eq('Doe')
      end

      it 'calls the extension function on update' do
        person = Person.create!(first_name: 'John', last_name: 'Doe')
        ActiveRecord::Base.connection.execute('TRUNCATE extension_test_log')

        person.update!(first_name: 'Jane')

        logs = ActiveRecord::Base.connection.execute('SELECT * FROM extension_test_log').to_a
        expect(logs.size).to eq(1)
        expect(logs.first['rec_table']).to eq('people')
        expect(logs.first['operation']).to eq('u')

        change = IrontrailChange.where(id: logs.first['change_id']).take
        expect(change.rec_old['first_name']).to eq('John')
        expect(change.rec_new['first_name']).to eq('Jane')
        expect(change.rec_old['last_name']).to eq('Doe')
        expect(change.rec_new['last_name']).to eq('Doe')
      end

      it 'calls the extension function on delete' do
        person = Person.create!(first_name: 'John', last_name: 'Doe')
        ActiveRecord::Base.connection.execute('TRUNCATE extension_test_log')

        person.destroy!

        logs = ActiveRecord::Base.connection.execute('SELECT * FROM extension_test_log').to_a
        expect(logs.size).to eq(1)
        expect(logs.first['rec_table']).to eq('people')
        expect(logs.first['operation']).to eq('d')

        change = IrontrailChange.where(id: logs.first['change_id']).take
        expect(change.rec_old['id']).to eq(person.id)
        expect(change.rec_old['first_name']).to eq('John')
        expect(change.rec_old['last_name']).to eq('Doe')
      end

      it 'includes the change_id in the extension call' do
        person = Person.create!(first_name: 'John', last_name: 'Doe')

        logs = ActiveRecord::Base.connection.execute('SELECT * FROM extension_test_log').to_a
        change_id = logs.first['change_id']

        change = IrontrailChange.where(id: change_id).first
        expect(change.rec_table).to eq('people')
        expect(change.rec_id).to eq(person.id.to_s)
      end
    end

    context 'when extension is disabled' do
      before do
        IrontrailChangeCallback.create!(
          rec_table: 'people',
          function_name: 'test_extension_function',
          enabled: false
        )
      end

      it 'does not call the extension function' do
        Person.create!(first_name: 'John', last_name: 'Doe')

        logs = ActiveRecord::Base.connection.execute('SELECT * FROM extension_test_log').to_a
        expect(logs.size).to eq(0)
      end
    end

    context 'when multiple extensions are registered for the same table' do
      before do
        # Create another test function
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE OR REPLACE FUNCTION test_extension_function_2(
            p_change_id BIGINT,
            p_rec_table TEXT,
            p_operation TEXT
          ) RETURNS VOID AS $$
          BEGIN
            INSERT INTO extension_test_log (change_id, rec_table, operation)
            VALUES (p_change_id, p_rec_table || '_2', p_operation);
          END;
          $$ LANGUAGE plpgsql;
        SQL

        IrontrailChangeCallback.create!(
          rec_table: 'people',
          function_name: 'test_extension_function',
          enabled: true
        )
        IrontrailChangeCallback.create!(
          rec_table: 'people',
          function_name: 'test_extension_function_2',
          enabled: true
        )
      end

      after do
        ActiveRecord::Base.connection.execute(
          'DROP FUNCTION IF EXISTS test_extension_function_2(BIGINT, TEXT, TEXT)'
        )
      end

      it 'calls all enabled extensions' do
        Person.create!(first_name: 'John', last_name: 'Doe')

        logs = ActiveRecord::Base.connection.execute('SELECT * FROM extension_test_log ORDER BY id').to_a
        expect(logs.size).to eq(2)
        expect(logs[0]['rec_table']).to eq('people')
        expect(logs[1]['rec_table']).to eq('people_2')
      end
    end

    context 'when extension is registered for different table' do
      before do
        IrontrailChangeCallback.create!(
          rec_table: 'hotels',
          function_name: 'test_extension_function',
          enabled: true
        )
      end

      it 'does not call the extension for other tables' do
        Person.create!(first_name: 'John', last_name: 'Doe')

        logs = ActiveRecord::Base.connection.execute('SELECT * FROM extension_test_log').to_a
        expect(logs.size).to eq(0)
      end
    end
  end

  describe 'model validations and scopes' do
    it 'validates presence of rec_table' do
      extension = IrontrailChangeCallback.new(function_name: 'test_func')
      expect(extension).not_to be_valid
      expect(extension.errors[:rec_table]).to be_present
    end

    it 'validates presence of function_name' do
      extension = IrontrailChangeCallback.new(rec_table: 'users')
      expect(extension).not_to be_valid
      expect(extension.errors[:function_name]).to be_present
    end

    describe '.enabled' do
      it 'returns only enabled extensions' do
        IrontrailChangeCallback.create!(
          rec_table: 'users',
          function_name: 'func1',
          enabled: true
        )
        IrontrailChangeCallback.create!(
          rec_table: 'users',
          function_name: 'func2',
          enabled: false
        )

        expect(IrontrailChangeCallback.enabled.pluck(:function_name)).to eq(['func1'])
      end
    end

    describe '.for_table' do
      it 'returns extensions for specific table' do
        IrontrailChangeCallback.create!(
          rec_table: 'users',
          function_name: 'func1',
          enabled: true
        )
        IrontrailChangeCallback.create!(
          rec_table: 'people',
          function_name: 'func2',
          enabled: true
        )

        expect(IrontrailChangeCallback.for_table('people').pluck(:function_name)).to eq(['func2'])
      end
    end
  end
end
