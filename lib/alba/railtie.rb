# frozen_string_literal: true

module Alba
  # Rails integration
  class Railtie < Rails::Railtie
    initializer 'alba.initialize' do
      Alba.inflector = :active_support

      ActiveSupport.on_load(:action_controller) do
        define_method(:serialize) do |obj, params: {}, with: nil, root_key: nil, meta: {}, &block|
          resource = with.nil? ? Alba.resource_for(obj, params: params, &block) : with.new(obj, params: params)
          resource.to_json(root_key: root_key, meta: meta)
        end

        define_method(:render_serialized_json) do |obj, params: {}, with: nil, root_key: nil, meta: {}, &block|
          json = with.nil? ? Alba.resource_for(obj, params: params, &block) : with.new(obj, params: params)
          render json: json.to_json(root_key: root_key, meta: meta)
        end
      end
    end
  end
end
