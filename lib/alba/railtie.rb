# frozen_string_literal: true

module Alba
  class Railtie < Rails::Railtie
    config.before_initialize do
      Alba.inflector = :active_support
    end
  end
end
