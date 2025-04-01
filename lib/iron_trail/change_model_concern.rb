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

      # Allows filtering out updates that changed just a certain set of columns.
      # This could be useful, for instance, to filter out updates made with
      # ActiveRecord's #touch method, which changes only the updated_at column.
      # In that case, calling `.with_delta_other_than(:updated_at)` would exclude
      # such changes from the result.
      #
      # This works by inspecting whether there are any keys in the rec_delta column
      # other than the columns specified in the `columns` parameter.
      def with_delta_other_than(*columns)
        quoted_columns = columns.map { |col_name| connection.quote(col_name) }
        exclude_array = "ARRAY[#{quoted_columns.join(', ')}]::text[]"

        sql = "rec_delta IS NULL OR (rec_delta - #{exclude_array}) <> '{}'::jsonb"
        where(::Arel::Nodes::SqlLiteral.new(sql))
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
            ::Arel::Nodes::SqlLiteral.new("#{col_delta}->>#{ary_index}").eq(
              ::Arel::Nodes::BindParam.new(value.to_s)
            )
          end

          scope.where!(node)
        end

        scope
      end
    end
  end
end
