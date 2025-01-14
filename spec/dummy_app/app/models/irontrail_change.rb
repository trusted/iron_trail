# frozen_string_literal: true

class IrontrailChange < ApplicationRecord
  include IronTrail::ChangeModelConcern

  scope :inserts, -> { where(operation: 'i') }
  scope :updates, -> { where(operation: 'u') }
  scope :deletes, -> { where(operation: 'd') }
end
