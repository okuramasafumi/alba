# frozen_string_literal: true

module Alba
  class Railtie < Rails::Railtie
    config.before_initialize do
      raise "before_initialize called"
      Alba.inflector = :active_support
    end
  end
end
