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
end
