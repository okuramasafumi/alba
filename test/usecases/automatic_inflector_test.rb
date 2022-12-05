require_relative '../test_helper'

require 'rack/test'
require 'action_controller/railtie'

class RailsApp < Rails::Application
  config.eager_load = false
  config.hosts << proc { true }
end

Rails.application.initialize!

class RailsAppController < ActionController::Base
  require 'alba'

  def index
    render plain: "Alba.inflector = #{Alba.inflector}"
  end
end

RailsApp.routes.draw do
  root to: 'rails_app#index'
end

class AutomaticInflectorTest < MiniTest::Test
  def app
    Rails.application
  end

  def test_rails_app
    extend Rack::Test::Methods

    get '/'
    assert_equal 'Alba.inflector = :active_support', last_response.body
  end
end
