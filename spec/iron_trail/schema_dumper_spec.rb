# frozen_string_literal: true

RSpec.describe IronTrail::SchemaDumper do
  let(:stream) { StringIO.new }
  let(:connection) { ActiveRecord::Base.connection }

  def dump_schema(conn = connection)
    # Rails 7.2+ takes a pool, Rails 7.1 takes a connection
    dump_target = ActiveRecord::SchemaDumper.method(:dump).parameters.first[1] == :pool ? conn.pool : conn
    ActiveRecord::SchemaDumper.dump(dump_target, stream)
    stream.string
  end

  describe '#trailer' do
    context 'when the database is not ignored' do
      it 'includes IronTrail.post_schema_load in the schema dump' do
        output = dump_schema

        expect(output).to include('IronTrail.post_schema_load')
      end
    end

    context 'when the database is ignored' do
      it 'does not include IronTrail.post_schema_load in the schema dump' do
        db_name = connection.pool.db_config.name

        IronTrail.config.ignored_databases << db_name
        output = dump_schema

        expect(output).not_to include('IronTrail.post_schema_load')
      ensure
        IronTrail.config.ignored_databases.delete(db_name)
      end
    end

    context 'when IronTrail is disabled' do
      it 'does not include IronTrail.post_schema_load in the schema dump' do
        IronTrail.config.enable = false
        output = dump_schema

        expect(output).not_to include('IronTrail.post_schema_load')
      ensure
        IronTrail.config.enable = true
      end
    end
  end
end
