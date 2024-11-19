# frozen_string_literal: true

module IronTrail
  class Association < ::ActiveRecord::Associations::HasManyAssociation
    def association_scope
      klass = self.klass
      reflection = self.reflection
      scope = klass.unscoped
      owner = self.owner

      chain = [::ActiveRecord::Reflection::RuntimeReflection.new(reflection, self)]

      foreign_key = reflection.join_foreign_key
      pk_value = owner._read_attribute(foreign_key)
      pk_table = owner.class.arel_table

      scope.where!('record_id' => pk_value, 'record_table' => pk_table.name)

      scope
    end

    # def load_target
    #   if find_target?
    #     @target = merge_target_lists(find_target, target)
    #   end
    #
    #   loaded!
    #   target
    # end

    # parent method implementation at:
    # https://github.com/rails/rails/blob/v7.2.2/activerecord/lib/active_record/associations/association.rb#L226-L250
    def find_target
      scope.to_a
    end
  end
end
