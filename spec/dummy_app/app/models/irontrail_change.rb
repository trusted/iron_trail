# frozen_string_literal: true

class IrontrailChange < ApplicationRecord
  include PgParty::Model
  include IronTrail::ChangeModelConcern

  range_partition_by { :created_at }

  scope :inserts, -> { where(operation: 'i') }
  scope :updates, -> { where(operation: 'u') }
  scope :deletes, -> { where(operation: 'd') }
end
