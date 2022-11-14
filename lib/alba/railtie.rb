module Alba
  class Railtie < Rails::Railtie
    # If Alba is being used in a Rails app, set the inflector by default.
    # Uses before_initialize so the user can override in an initializer in their app.
    config.before_initialize do
      Alba.inflector = :active_support
    end
  end
end
