# frozen_string_literal: true

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
    base_controller = Class.new(ActionController::Base)
    api_controller = Class.new(ActionController::API)
    assert_includes base_controller.instance_methods, :serialize
    assert_includes api_controller.instance_methods, :serialize
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

  class FoosAPIController < ActionController::API
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
    controller = controller_instance(FoosController)
    controller.show
    assert_equal '{"id":1,"name":"foo"}', controller.response_body.first
  end

  def test_foos_api_controller_show
    controller = controller_instance(FoosAPIController)
    controller.show
    assert_equal '{"id":1,"name":"foo"}', controller.response_body.first
  end

  def test_foos_controller_index
    controller = controller_instance(FoosController)
    controller.index
    assert_equal '[{"id":1,"name":"foo"}]', controller.response_body.first
  end

  def test_foos_api_controller_index
    controller = controller_instance(FoosAPIController)
    controller.index
    assert_equal '[{"id":1,"name":"foo"}]', controller.response_body.first
  end

  private

  def controller_instance(controller_class)
    controller = controller_class.new
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
