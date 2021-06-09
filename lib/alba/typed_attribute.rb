module Alba
  # Representing typed attributes to encapsulate logic about types
  class TypedAttribute
    # @param name [Symbol, String]
    # @param type [Symbol, Class]
    # @param converter [Proc]
    def initialize(name:, type:, converter:)
      @name = name
      @type = type
      @converter = case converter
                   when true then default_converter
                   when false, nil then null_converter
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
      value = object.public_send(@name)
      type_correct = case @type
                     when :String, ->(klass) { klass == String } then value.is_a?(String)
                     when :Integer, ->(klass) { klass == Integer } then value.is_a?(Integer)
                     when :Boolean then [true, false].include?(value)
                     else
                       raise Alba::UnsupportedType, "Unknown type: #{@type}"
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
        raise Alba::UnsupportedType, "Unknown type: #{@type}"
      end
    end

    def null_converter
      ->(_) { raise TypeError }
    end

    def display_value_for(value)
      value.nil? ? 'nil' : value.class.name
    end
  end
end
