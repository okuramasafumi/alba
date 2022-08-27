begin
  require 'active_support/inflector'
  require 'active_support/core_ext/module/delegation'
rescue LoadError
  raise ::Alba::Error, 'To use default inflector, please install `ActiveSupport` gem.'
end

module Alba
  # This module has two purposes.
  # One is that we require `active_support/inflector` in this module so that we don't do that all over the place.
  # Another is that `ActiveSupport::Inflector` doesn't have `camelize_lower` method that we want it to have, so this module works as an adapter.
  module DefaultInflector
    class << self
      delegate :camelize, :dasherize, :underscore, :classify, :demodulize, :pluralize, to: ActiveSupport::Inflector
    end

    # Camelizes a key, 1st letter lowercase
    #
    # @param key [String] key to be camelized
    # @return [String] camelized key
    def self.camelize_lower(key)
      ActiveSupport::Inflector.camelize(key, false)
    end
  end
end
