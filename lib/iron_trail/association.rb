# frozen_string_literal: true

module IronTrail
  class Association < ::ActiveRecord::Associations::HasManyAssociation
    def association_scope
      scope = klass.unscoped

      foreign_key = reflection.join_foreign_key
      pk_value = owner._read_attribute(foreign_key)
      pk_table = owner.class.arel_table

      scope.where!('rec_id' => pk_value, 'rec_table' => pk_table.name)

      scope
    end

    def find_target
      scope.to_a
    end
  end
end
