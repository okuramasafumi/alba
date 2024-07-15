# frozen_string_literal: true

module Alba
  # Representing type itself, combined with {Alba::TypedAttribute}
  class Type
    attr_reader :name
    attr_writer :auto_convert

    # @param name [Symbol, String] name of the type
    # @param check [Proc, Boolean] proc to check type
    #   If false, type check is skipped
    # @param converter [Proc] proc to convert type
    # @param auto_convert [Boolean] whether to convert type automatically
    def initialize(name, check:, converter:, auto_convert: false)
      @name = name
      @check = check
      @converter = converter
      @auto_convert = auto_convert
    end

    # Type check
    #
    # @param value [Object] value to check
    # @return [Boolean] the result of type check
    def check(value)
      @check == false ? false : @check.call(value)
    end

    # Type convert
    # If @auto_convert is true, @convert proc is called with obj
    # Otherwise, it raises an exception that is caught by {Alba::TypedAttribute}
    #
    # @param obj [Object] object to convert
    def convert(obj)
      @auto_convert ? @converter.call(obj) : raise(TypeError)
    end

    # Enable auto convert with given converter
    # @param converter [Proc] proc to convert type
    def auto_convert_with(converter)
      @converter = converter
      @auto_convert = true
    end
  end
end
