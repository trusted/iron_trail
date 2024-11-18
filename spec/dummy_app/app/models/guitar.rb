# frozen_string_literal: true

# class IronTrailFakeAssoc < ActiveRecord::Associations::CollectionAssociation
class IronTrailFakeAssoc < ActiveRecord::Associations::HasManyAssociation
  def association_scope
    klass = self.klass
    reflection = self.reflection
    scope = klass.unscoped
    owner = self.owner

    chain = [ActiveRecord::Reflection::RuntimeReflection.new(reflection, self)]

    foreign_key = reflection.join_foreign_key
    pk_value = owner._read_attribute(foreign_key)
    pk_table = owner.class.arel_table
    scope.where!('record_id' => pk_value, 'record_table' => pk_table.name)

    scope
  end

  # parent method implementation at:
  # https://github.com/rails/rails/blob/v7.2.2/activerecord/lib/active_record/associations/association.rb#L226-L250
  def find_target
    scope.to_a
  end
end

# TODO: remove
module IronTrailExtensions
end

class IronTrailReflection < ActiveRecord::Reflection::AssociationReflection
  def collection?; true; end

  def association_class
    IronTrailFakeAssoc
  end

  # TODO: remove
  def extensions
    Array(options[:extend]) + [IronTrailExtensions]
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
    foreign_value = Arel::Nodes::NamedFunction.new(
      'CAST',
      [
        Arel::Nodes::As.new(
          foreign_table[foreign_key_column_name],
          Arel::Nodes::SqlLiteral.new('text')
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
end

class Guitar < ApplicationRecord
  belongs_to :person
  has_many :guitar_parts

  # just imagine if rails would be like this!
  ActiveRecord::Reflection.add_reflection(
    self,
    :trails,
    IronTrailReflection.new(:trails, nil, { class_name: 'IrontrailChange' }, self)
  )
  def trails
    association(:trails).reader
  end
end
