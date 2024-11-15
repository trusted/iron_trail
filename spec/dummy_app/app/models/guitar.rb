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
end

class IronTrailReflection < ActiveRecord::Reflection::AssociationReflection
  def collection?; true; end

  def association_class
    IronTrailFakeAssoc
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
