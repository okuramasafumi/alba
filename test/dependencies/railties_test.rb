# Rails integration
require 'rails'
require_relative '../test_helper'
require 'alba/railtie'
require 'action_controller'

class RailtiesTest < Minitest::Test
  def setup
    Alba::Railtie.run_initializers
  end

  def test_railties
    assert_equal Alba::DefaultInflector, Alba.inflector
  end

  def test_rails_controller_integration
    controller = Class.new(ActionController::Base)
    assert_includes controller.instance_methods, :serialize
  end

  class FoosController < ActionController::Base
    def show
      foo = Foo.new(1, 'foo')
      render json: serialize(foo)
    end

    def index
      foo = Foo.new(1, 'foo')
      render_serialized_json([foo], with: FooResource)
    end
  end

  Foo = Struct.new(:id, :name)

  class FooResource
    include Alba::Resource

    attributes :id, :name
  end

  class FakeResponse
    attr_accessor :body

    def iniitalize
      @body = nil
    end

    def media_type
      :json
    end

    def headers
      {}
    end
  end

  def test_foos_controller_show
    controller = foos_controller
    controller.show
    assert_equal '{"id":1,"name":"foo"}', controller.response_body.first
  end

  def test_foos_controller_index
    controller = foos_controller
    controller.index
    assert_equal '[{"id":1,"name":"foo"}]', controller.response_body.first
  end

  private

  def foos_controller
    controller = FoosController.new
    # Mock the request and response
    request = Object.new.tap do |o|
      o.define_singleton_method(:variant) { :sp }
      o.define_singleton_method(:should_apply_vary_header?) { false }
    end
    response = FakeResponse.new

    # Assign instance variables as they would be set in a real request
    controller.instance_variable_set(:@_request, request)
    controller.instance_variable_set(:@_response, response)
    controller.instance_variable_set(:@_params, {})
    controller
  end
end
