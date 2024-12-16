# frozen_string_literal: true

module IronTrail
  module ChangeModelConcern
    extend ::ActiveSupport::Concern

    def reify
      klass = Guitar # FIXME:

      rec = klass.where(id: rec_id).first || klass.new
      source_attributes = (operation == 'd' ? rec_old : rec_new)

      source_attributes.each do |name, value|
        if rec.has_attribute?(name)
          rec[name.to_sym] = value
        elsif rec.respond_to?("#{name}=")
          rec.send("#{name}=", value)
        else
          ghost = rec.instance_variable_get(:@irontrail_reified_ghost_attributes)
          unless ghost
            ghost = HashWithIndifferentAccess.new
            rec.instance_variable_set(:@irontrail_reified_ghost_attributes, ghost)
          end
          ghost[name] = value
        end
      end

      rec
    end

    module ClassMethods
      def where_object_changes_to(args = {})
        _where_object_changes(1, args)
      end

      def where_object_changes_from(args = {})
        _where_object_changes(0, args)
      end

      private

      def _where_object_changes(ary_index, args)
        scope = all

        args.each do |col_name, value|
          scope.where!(
            ::Arel::Nodes::SqlLiteral.new("rec_delta->#{connection.quote col_name}->>#{Integer(ary_index)}").eq(
              ::Arel::Nodes::BindParam.new(value)
            )
          )
        end

        scope
      end
    end
  end
end
