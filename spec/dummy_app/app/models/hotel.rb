# frozen_string_literal: true

class Hotel < ApplicationRecord
  include IronTrail::Model

  has_one :owner_person,
    class_name: 'Person',
    inverse_of: :owns,
    dependent: :destroy
end
