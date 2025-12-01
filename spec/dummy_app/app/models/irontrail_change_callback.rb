# frozen_string_literal: true

class IrontrailChangeCallback < ApplicationRecord
  include IronTrail::Model

  validates :rec_table, presence: true
  validates :function_name, presence: true
  validates :enabled, inclusion: { in: [true, false] }

  scope :enabled, -> { where(enabled: true) }
  scope :for_table, ->(table_name) { where(rec_table: table_name) }
end
