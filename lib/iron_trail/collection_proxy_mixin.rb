# frozen_string_literal: true

module IronTrail
  module CollectionProxyMixin
    def travel_to(ts)
      arel_table = arel.ast.cores.first.source.left

      changes = scope
        .order(arel_table[:created_at] => :desc)
        .where(arel_table[:created_at].lteq(ts))

      lower_bound = travel_to_lower_bound(ts)
      change_record = (changes.where(arel_table[:created_at].gteq(lower_bound)).first if lower_bound)
      change_record ||= changes.first

      change_record&.reify
    end

    private

    # Changes are stamped with the record's created_at/updated_at or a later time, so the change
    # travel_to wants is almost always at or after the record's latest timestamp up to ts. Bounding
    # the lookup there lets Postgres skip older partitions of irontrail_changes. If no change is in
    # the bound (e.g. updated_at moved with tracking disabled), the unbounded lookup still runs.
    def travel_to_lower_bound(ts)
      return if ts.nil?

      owner = proxy_association.owner
      %w[created_at updated_at]
        .filter_map { |name| owner._read_attribute(name) if owner.has_attribute?(name) }
        .select { |timestamp| timestamp <= ts }
        .max
    end
  end
end
