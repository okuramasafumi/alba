require_relative '../test_helper'

class LayoutTest < MiniTest::Test
  class User
    attr_accessor :id, :name, :email

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
    end
  end

  class UserResource
    include Alba::Resource

    attributes :id, :name
  end

  def setup
    Alba.backend = nil

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
  end

  class UserResourceWithSimpleLayout < UserResource
    layout file: 'test/support/simple_layout.json.erb'
  end

  def test_it_renders_json_within_layout
    assert_equal(
      {'header' => 'my header', 'body' => {'id' => 1, 'name' => 'Masafumi OKURA'}}, # rubocop:disable Style/StringHashKeys
      JSON.parse(UserResourceWithSimpleLayout.new(@user).serialize)
    )
  end

  class UserResourceWithPaginationLayout < UserResource
    layout file: 'test/support/pagination_layout.json.erb'
  end

  def test_it_renders_json_within_layout_using_params
    assert_equal(
      {'body' => {'id' => 1, 'name' => 'Masafumi OKURA'}, 'pagination' => {'page' => 1}}, # rubocop:disable Style/StringHashKeys
      JSON.parse(UserResourceWithPaginationLayout.new(@user, params: {pagination: {page: 1}}).serialize)
    )
  end
end
