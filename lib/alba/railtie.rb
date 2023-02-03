module Alba
  # Rails integration
  class Railtie < Rails::Railtie
    initializer 'alba.initialize' do
      Alba.inflector = :active_support
    end
  end
end
