module Alba
  # Representing typed attributes to encapsulate logic about types
  # @api private
  class TypedAttribute
    # @param name [Symbol, String]
    # @param type [Symbol, Class]
    # @param converter [Proc]
    def initialize(name:, type:, converter:)
      @name = name
      @type = type
      @converter = case converter
                   when true then default_converter
                   when false, nil then find_converter
                   else converter
                   end
    end

    # @param object [Object] target to check and convert type with
    # @return [String, Integer, Boolean] type-checked or type-converted object
    def value(object)
      value, result = check(object)
      result ? value : @converter.call(value)
    rescue TypeError
      raise TypeError, "Attribute #{@name} is expected to be #{@type} but actually #{display_value_for(value)}."
    end

    private

    def check(object)
      value = object.__send__(@name)
      type_correct = case @type
                     when :String, ->(klass) { klass == String } then value.is_a?(String)
                     when :Integer, ->(klass) { klass == Integer } then value.is_a?(Integer)
                     when :Boolean then [true, false].include?(value)
                     else
                       check_custom_types(value)
                     end
      [value, type_correct]
    end

    def default_converter
      case @type
      when :String, ->(klass) { klass == String }
        ->(object) { object.to_s }
      when :Integer, ->(klass) { klass == Integer }
        ->(object) { Integer(object) }
      when :Boolean
        ->(object) { !!object }
      else
        converter_for_custom_types
      end
    end

    def find_converter
      if custom_type
        converter_for_custom_types
      else
        ->(_) { raise TypeError }
      end
    end

    def display_value_for(value)
      value.nil? ? 'nil' : value.class.name
    end

    def check_custom_types(value)
      custom_type ? custom_type.check(value) : raise(Alba::UnsupportedType, "Unknown type: #{@type}")
    end

    def converter_for_custom_types
      ->(object) { custom_type.convert(object) }
    end

    def custom_type
      @custom_type ||= Alba.types.find { |t| t.name == @type }
    end
  end
end
