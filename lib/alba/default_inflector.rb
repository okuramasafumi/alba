module Alba
  # This module represents the inflector, which is used by default
  module DefaultInflector
    begin
      require 'active_support/inflector'
    rescue LoadError
      raise ::Alba::Error, 'To use transform_keys, please install `ActiveSupport` gem.'
    end

    module_function

    # Camelizes a key
    #
    # @params key [String] key to be camelized
    # @return [String] camelized key
    def camelize(key)
      ActiveSupport::Inflector.camelize(key)
    end

    # Camelizes a key, 1st letter lowercase
    #
    # @params key [String] key to be camelized
    # @return [String] camelized key
    def camelize_lower(key)
      ActiveSupport::Inflector.camelize(key, false)
    end

    # Dasherizes a key
    #
    # @params key [String] key to be dasherized
    # @return [String] dasherized key
    def dasherize(key)
      ActiveSupport::Inflector.dasherize(key)
    end
  end
end
