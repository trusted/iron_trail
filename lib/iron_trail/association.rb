# frozen_string_literal: true

module IronTrail
  module CollectionProxyMixin
    def version_at(ts)
      arel_table = arel.ast.cores.first.source.left

      change_record = scope
        .order(arel_table[:created_at] => :desc)
        .where(arel_table[:created_at].lteq(ts))
        .first

      change_record.reify
    end
  end

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

      scope.where!('rec_id' => pk_value, 'rec_table' => pk_table.name)

      scope
    end

    def reader
      rdr = super
      rdr.extend(::IronTrail::CollectionProxyMixin)

      rdr
    end

    def find_target
      scope.to_a
    end
  end
end
