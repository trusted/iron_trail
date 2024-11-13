# frozen_string_literal: true

class IrontrailChange < ApplicationRecord
  include PgParty::Model

  range_partition_by { "(created_at::date)" }
end
