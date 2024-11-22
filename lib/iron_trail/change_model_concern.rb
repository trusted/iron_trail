# frozen_string_literal: true

module IronTrail
  module ChangeModelConcern
    extend ::ActiveSupport::Concern

    module ClassMethods
      def where_object_changes_to(args = {})
        scope = all

        args.each do |col_name, value|
          scope.where!(
            ::Arel::Nodes::SqlLiteral.new("rec_delta->#{connection.quote col_name}->>1").eq(
              ::Arel::Nodes::BindParam.new(value)
            )
          )
        end

        scope
        # where_object_changes(0, args)
      end

      def where_object_changes_from(args = {})
        where_object_changes(0, args)
      end

      private

      def where_object_changes(ary_index, args)
      end
    end
  end
end
