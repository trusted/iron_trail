# frozen_string_literal: true

class Guitar < ApplicationRecord
  include IronTrail::Model

  belongs_to :person
  has_many :guitar_parts
end
