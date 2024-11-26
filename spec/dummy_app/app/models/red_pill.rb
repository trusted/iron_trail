# frozen_string_literal: true

class RedPill < MatrixPill
  has_many :converts,
    class_name: 'Person',
    inverse_of: :converted_by_pill
  # foreign_key: 'converted_by_pill'
end
