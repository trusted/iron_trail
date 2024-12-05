# frozen_string_literal: true

class Person < ApplicationRecord
  include IronTrail::Model

  has_many :guitars
  belongs_to :converted_by_pill,
    optional: true,
    polymorphic: true,
    class_name: 'MatrixPill'

  def full_name
    "#{first_name} #{last_name}"
  end
end
