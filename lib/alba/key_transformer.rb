module Alba
  # Transform keys using `ActiveSupport::Inflector`
  module KeyTransformer
    begin
      require 'active_support/inflector'
    rescue LoadError
      raise ::Alba::Error, 'To use transform_keys, please install `ActiveSupport` gem.'
    end

    module_function

    # Transform key as given transform_type
    #
    # @params key [String] key to be transformed
    # @params transform_type [Symbol] transform type
    # @return [String] transformed key
    # @raise [Alba::Error] when transform_type is not supported
    def transform(key, transform_type)
      key = key.to_s
      case transform_type
      when :camel
        ActiveSupport::Inflector.camelize(key)
      when :lower_camel
        ActiveSupport::Inflector.camelize(key, false)
      when :dash
        ActiveSupport::Inflector.dasherize(key)
      else
        raise ::Alba::Error, "Unknown transform_type: #{transform_type}. Supported transform_type are :camel, :lower_camel and :dash."
      end
    end
  end
end
