# frozen_string_literal: true

module IronTrail
  # TODO: remove?
  module ReflectionExtensions
  end

  class Reflection < ::ActiveRecord::Reflection::AssociationReflection
    def collection?; true; end

    def association_class
      ::IronTrail::Association
    end

    # TODO: remove
    def extensions
      Array(options[:extend]) + [ReflectionExtensions]
    end

    def join_scope(table, foreign_table, foreign_klass)
      predicate_builder = predicate_builder(table)
      scope_chain_items = join_scopes(table, predicate_builder)
      klass_scope       = klass_join_scope(table, predicate_builder)

      # TODO: what is this all about?
      # scope_chain_items.inject(klass_scope, &:merge!)

      foreign_key_column_names = Array(join_foreign_key)
      # TODO: trigger exception if key is composite? (foreign_key_column_names.length > 1)
      foreign_key_column_name = foreign_key_column_names.first

      # record_id is always of type text, but the foreign table primary key
      # could be anything (int, uuid, ...)
      foreign_value = ::Arel::Nodes::NamedFunction.new(
        'CAST',
        [
          ::Arel::Nodes::As.new(
            foreign_table[foreign_key_column_name],
            ::Arel::Nodes::SqlLiteral.new('text')
          ),
        ]
      )

      klass_scope.where!(
        table['record_id']
          .eq(foreign_value)
          .and(
            table['record_table']
            .eq(foreign_table.name)
          )
      )

      klass_scope
    end

    def association_foreign_key
      debugger
      x=1
    end

    def association_primary_key(klass = nil)
      debugger
      x=1
    end
  end
end
