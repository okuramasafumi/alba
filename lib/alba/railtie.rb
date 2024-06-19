module Alba
  # Rails integration
  class Railtie < Rails::Railtie
    initializer 'alba.initialize' do
      Alba.inflector = :active_support

      ActiveSupport.on_load(:action_controller) do
        ActionController::Base.define_method(:serialize) do |obj, with: nil, &block|
          with.nil? ? Alba.resource_with(obj, &block) : with.new(obj)
        end

        ActionController::Base.define_method(:render_serialized_json) do |obj, with: nil, &block|
          json = with.nil? ? Alba.resource_with(obj, &block) : with.new(obj)
          render json: json
        end
      end
    end
  end
end
