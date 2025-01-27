# frozen_string_literal: true

class GuitarPart < ApplicationRecord
  include IronTrail::Model

  belongs_to :guitar
end
