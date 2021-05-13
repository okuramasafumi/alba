module Alba
  module KeyTransformFactory

    module_function

    def inflector
      @inflector ||= begin
          require "active_support/inflector"
          ActiveSupport::Inflector
        rescue LoadError
          raise ::Alba::Error, "To use transform_keys, please install `ActiveSupport` gem."
        end
    end

    # Create key transform function for given transform_type
    #
    # @params transform_type [Symbol] transform type
    # @return [Proc] transform function
    # @raise [Alba::Error] when transform_type is not supported
    def create(transform_type)
      case transform_type
      when :camel
        ->(key) { inflector.camelize(key) }
      when :lower_camel
        ->(key) { inflector.camelize(key, false) }
      when :dash
        ->(key) { inflector.dasherize(key) }
      else
        raise ::Alba::Error, "Unknown transform_type: #{transform_type}. Supported transform_type are :camel, :lower_camel and :dash."
      end
    end
  end
end