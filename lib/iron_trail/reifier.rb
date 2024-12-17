# frozen_string_literal: true

module IronTrail
  module Reifier
    def self.reify(trail)
      klass = model_from_table_name(trail.rec_table)

      record = klass.where(id: trail.rec_id).first || klass.new
      source_attributes = (trail.operation == 'd' ? trail.rec_old : trail.rec_new)

      source_attributes.each do |name, value|
        if record.has_attribute?(name)
          record[name.to_sym] = value
        elsif record.respond_to?("#{name}=")
          record.send("#{name}=", value)
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

    def self.model_from_table_name(table_name)
      # TODO: this won't work with STI models.
      index = ActiveRecord::Base.descendants.reject(&:abstract_class).index_by(&:table_name)
      klass = index[table_name]
      raise "Cannot infer model from table named '#{table_name}'" unless klass

      klass
    end
  end
end
