# frozen_string_literal: true

# raise "this file is loaded"

Hanami.app.register_provider :alba do
  # raise "register_provider is called"
  prepare do
    raise "prepare is called"
    require "alba"
    Alba.inflector = target["inflector"]
  end
end
