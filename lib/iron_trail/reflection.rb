# frozen_string_literal: true

module IronTrail
  class Reflection < ::ActiveRecord::Reflection::AssociationReflection
    def collection?; true; end

    def association_class
      ::IronTrail::Association
    end

    def join_scope(table, foreign_table, foreign_klass)
      scope = klass_join_scope(table, nil)

      foreign_key_column_names = Array(join_foreign_key)
      if foreign_key_column_names.length > 1
        raise "IronTrail does not support composite foreign keys (got #{foreign_key_column_names})"
      end

      foreign_key_column_name = foreign_key_column_names.first

      # record_id is always of type text, but the foreign table primary key
      # could be anything (int, uuid, ...), so let's cast it to text.
      foreign_value = ::Arel::Nodes::NamedFunction.new(
        'CAST',
        [
          ::Arel::Nodes::As.new(
            foreign_table[foreign_key_column_name],
            ::Arel::Nodes::SqlLiteral.new('text')
          ),
        ]
      )

      scope.where!(
        table['rec_id']
          .eq(foreign_value)
          .and(
            table['rec_table']
            .eq(foreign_table.name)
          )
      )

      scope
    end
  end
end
