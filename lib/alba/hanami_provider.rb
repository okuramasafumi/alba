# frozen_string_literal: true

Hanami.app.register_provider :alba do
  prepare do
    require "alba"
    Alba.inflector = target["inflector"]
  end
end
