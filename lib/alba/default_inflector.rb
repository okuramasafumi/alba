module Alba
  # This module has two purposes.
  # One is that we require `active_support/inflector` in this module so that we don't do that all over the place.
  # Another is that `ActiveSupport::Inflector` doesn't have `camelize_lower` method that we want it to have, so this module works as an adapter.
  module DefaultInflector
    begin
      require 'active_support/inflector'
    rescue LoadError
      raise ::Alba::Error, 'To use transform_keys, please install `ActiveSupport` gem.'
    end

    module_function

    # Camelizes a key
    #
    # @param key [String] key to be camelized
    # @return [String] camelized key
    def camelize(key)
      ActiveSupport::Inflector.camelize(key)
    end

    # Camelizes a key, 1st letter lowercase
    #
    # @param key [String] key to be camelized
    # @return [String] camelized key
    def camelize_lower(key)
      ActiveSupport::Inflector.camelize(key, false)
    end

    # Dasherizes a key
    #
    # @param key [String] key to be dasherized
    # @return [String] dasherized key
    def dasherize(key)
      ActiveSupport::Inflector.dasherize(key)
    end

    # Underscore a key
    #
    # @param key [String] key to be underscore
    # @return [String] underscored key
    def underscore(key)
      ActiveSupport::Inflector.underscore(key)
    end

    # Classify a key
    #
    # @param key [String] key to be classified
    # @return [String] classified key
    def classify(key)
      ActiveSupport::Inflector.classify(key)
    end
  end
end
