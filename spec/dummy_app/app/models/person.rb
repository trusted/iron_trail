# frozen_string_literal: true

class Person < ApplicationRecord
  include IronTrail::Model

  has_many :guitars

  belongs_to :converted_by_pill,
    optional: true,
    polymorphic: true,
    class_name: 'MatrixPill'

  belongs_to :owns,
    class_name: 'Hotel',
    foreign_key: :owns_the_hotel,
    optional: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
