# frozen_string_literal: true

require "dry/system/provider/source"

module Alba
  class Provider < Dry::System::Provider::Source
    def prepare
      require "alba"
    end

    def start
      Alba.inflector = target_container["inflector"]
    end
  end
end

if defined?(Hanami)
  Hanami.app.register_provider(:alba, source: Alba::Provider)
end
