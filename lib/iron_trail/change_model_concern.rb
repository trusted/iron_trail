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
        scope = all

        args.each do |col_name, value|
          scope.where!(
            ::Arel::Nodes::SqlLiteral.new("rec_delta->#{connection.quote col_name}->>#{Integer(ary_index)}").eq(
              ::Arel::Nodes::BindParam.new(value.to_s)
            )
          )
        end

        scope
      end
    end
  end
end
