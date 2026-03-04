# frozen_string_literal: true

module IronTrail
  module Reifier
    def self.reify(trail)
      source_attributes = (trail.delete_operation? ? trail.rec_old : trail.rec_new)
      klass = model_from_table_name(trail.rec_table, source_attributes['type'])

      record = klass.where(id: trail.rec_id).first || klass.new

      source_attributes.each do |name, value|
        if record.has_attribute?(name)
          attr_type = record.type_for_attribute(name)
          record[name] = attr_type.deserialize(value)
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

    def self.model_from_table_name(table_name, sti_type = nil)
      candidates = ActiveRecord::Base.descendants
        .reject(&:abstract_class)
        .select { |klass| klass.table_name == table_name }
        .select { |klass| klass.name.present? && klass.name.safe_constantize == klass }

      raise "Cannot infer model from table named '#{table_name}'" if candidates.empty?
      return candidates.first if candidates.one?

      if sti_type.present?
        klass = candidates.find { |c| c.name == sti_type }
        return klass if klass

        raise "Cannot infer STI model for table #{table_name} and type '#{sti_type}'"
      end

      # When sti_type is nil and multiple classes share the table,
      # filter out STI subclasses to find the base class.
      bases = candidates.reject { |c| candidates.any? { |other| other != c && c < other } }
      return bases.first if bases.one?

      # If multiple base classes remain, prefer the one that is an STI base
      # (i.e., has subclasses among the original candidates).
      sti_bases = bases.select { |c| candidates.any? { |other| other != c && other < c } }
      return sti_bases.first if sti_bases.one?

      raise "Cannot infer model from table named '#{table_name}'"
    end
  end
end
