module Alba
  # Representing typed attributes to encapsulate logic about types
  # @api private
  class TypedAttribute
    # @param name [Symbol, String]
    # @param type [Symbol, Class]
    # @param converter [Proc]
    def initialize(name:, type:, converter:)
      @name = name
      t = real_type(type)
      @type = case converter
              when true then t.dup.tap { _1.auto_convert = true }
              when false, nil then t
              else
                t.dup.tap { _1.auto_convert_with(converter) }
              end
    end

    # @param object [Object] target to check and convert type with
    # @return [String, Integer, Boolean] type-checked or type-converted object
    def value(object)
      v = object.__send__(@name)
      result = @type.check(v)
      result ? v : @type.convert(v)
    rescue TypeError
      raise TypeError, "Attribute #{@name} is expected to be #{@type.name} but actually #{display_value_for(v)}."
    end

    private

    def real_type(type_name)
      result = Alba.types.find { |t| t.name == type_name }
      raise(Alba::UnsupportedType, "Unknown type: #{type_name}") unless result

      result
    end

    def display_value_for(value)
      value.nil? ? 'nil' : value.class.name
    end
  end
end
