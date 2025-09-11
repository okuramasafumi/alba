# frozen_string_literal: true

module Alba
  # Representing typed attributes to encapsulate logic about types
  # @api private
  class TypedAttribute
    attr_reader :name

    # @param name [Symbol, String]
    # @param type [Symbol, Class]
    # @param converter [Proc, true, false, nil]
    def initialize(name:, type:, converter:)
      @name = name
      t = Alba.find_type(type)
      @type = case converter
              when true then t.dup.tap { _1.auto_convert = true }
              when false, nil then t
              else
                t.dup.tap { _1.auto_convert_with(converter) }
              end
    end

    # @return [String, Integer, Boolean] type-checked or type-converted object
    def value
      v = yield(@name)
      result = @type.check(v)
      result ? v : @type.convert(v)
    rescue TypeError
      raise TypeError, "Attribute #{@name} is expected to be #{@type.name} but actually #{display_value_for(v)}."
    end

    private

    def display_value_for(value)
      value.nil? ? 'nil' : value.class.name
    end
  end
end
