# frozen_string_literal: true

module Alba
  # Rails integration
  class Railtie < Rails::Railtie
    initializer 'alba.initialize' do
      Alba.inflector = :active_support

      ActiveSupport.on_load(:action_controller) do
        define_method(:serialize) do |obj, with: nil, root_key: nil, meta: {}, &block|
          resource = with.nil? ? Alba.resource_for(obj, &block) : with.new(obj)
          resource.to_json(root_key: root_key, meta: meta)
        end

        define_method(:render_serialized_json) do |obj, with: nil, root_key: nil, meta: {}, &block|
          json = with.nil? ? Alba.resource_for(obj, &block) : with.new(obj)
          render json: json.to_json(root_key: root_key, meta: meta)
        end
      end
    end
  end
end
