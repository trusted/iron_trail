# frozen_string_literal: true

module IronTrail
  # Including this module will create something akin to:
  #   has_many :iron_trails
  #
  # But a has_many association here wouldn't suffice, so IronTrail has its
  # own AR reflection and association classes.
  module Model
    def self.included(mod)
      mod.include ClassMethods
      mod.attr_reader :irontrail_reified_ghost_attributes

      ::ActiveRecord::Reflection.add_reflection(
        mod,
        :iron_trails,
        ::IronTrail::Reflection.new(:iron_trails, nil, { class_name: 'IrontrailChange' }, mod)
      )
    end

    module ClassMethods
      def iron_trails
        association(:iron_trails).reader
      end
    end
  end
end
