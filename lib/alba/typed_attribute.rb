module Alba
  # Representing typed attributes to encapsulate logic about types
  class TypedAttribute
    # @param name [Symbol, String]
    # @param type [Symbol, Class]
    # @param converter [Proc]
    def initialize(name:, type:, converter:)
      @name = name
      @type = type
      @converter = converter == true ? default_converter : converter
    end

    # @param object [Object] target to check and convert type with
    # @return [String, Integer, Boolean] type-checked or type-converted object
    def value(object)
      value, result = check(object)
      return value if result

      raise TypeError if !result && !@converter

      @converter.call(value)
    rescue TypeError
      raise TypeError, "Attribute #{@name} is expected to be #{@type} but actually #{value.nil? ? 'nil' : value.class.name}."
    end

    private

    def check(object)
      value = object.public_send(@name)
      type_correct = case @type
                     when :String, ->(klass) { klass == String }
                       value.is_a?(String)
                     when :Integer, ->(klass) { klass == Integer }
                       value.is_a?(Integer)
                     when :Boolean
                       [true, false].include?(value)
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
  end
end
