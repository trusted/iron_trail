# frozen_string_literal: true

module IronTrail
  module Reifier
    def self.reify(trail)
      source_attributes = (trail.delete_operation? ? trail.rec_old : trail.rec_new)
      klass = model_from_table_name(trail.rec_table, source_attributes['type'])

      record = klass.where(id: trail.rec_id).first || klass.new

      source_attributes.each do |name, serialized_value|
        attr_type = record.type_for_attribute(name)
        value = attr_type.deserialize(serialized_value)

        if record.has_attribute?(name)
          record[name] = value
        else
          ghost = record.instance_variable_get(:@irontrail_reified_ghost_attributes)
          unless ghost
            ghost = HashWithIndifferentAccess.new
            record.instance_variable_set(:@irontrail_reified_ghost_attributes, ghost)
          end
          ghost[name] = value
        end
      end

      record
    end

    def self.model_from_table_name(table_name, sti_type=nil)
      index = ActiveRecord::Base.descendants.reject(&:abstract_class).chunk(&:table_name).to_h do |key, val|
        v = \
          if val.length == 1
            val[0]
          else
            val.to_h { |k| [k.to_s, k] }
          end

        [key, v]
      end

      klass = index[table_name]
      raise "Cannot infer model from table named '#{table_name}'" unless klass

      return klass unless klass.is_a?(Hash)
      klass = klass[sti_type]

      return klass if klass

      raise "Cannot infer STI model for table #{table_name} and type '#{sti_type}'"
    end
  end
end
