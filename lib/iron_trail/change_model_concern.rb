# frozen_string_literal: true

module IronTrail
  module ChangeModelConcern
    extend ::ActiveSupport::Concern

    def reify
      Reifier.reify(self)
    end

    def insert_operation? = (operation == 'i')
    def update_operation? = (operation == 'u')
    def delete_operation? = (operation == 'd')

    module ClassMethods
      def where_object_changes_to(args = {})
        _where_object_changes(1, args)
      end

      def where_object_changes_from(args = {})
        _where_object_changes(0, args)
      end

      private

      def _where_object_changes(ary_index, args)
        ary_index = Integer(ary_index)
        scope = all

        args.each do |col_name, value|
          col_delta = "rec_delta->#{connection.quote(col_name)}"
          node = if value == nil
            ::Arel::Nodes::SqlLiteral.new("#{col_delta}->#{ary_index} = 'null'::jsonb")
          else
            ::Arel::Nodes::SqlLiteral.new("#{col_delta}->>#{ary_index}").eq(::Arel::Nodes::BindParam.new(value.to_s))
          end

          scope.where!(node)
        end

        scope
      end
    end
  end
end
