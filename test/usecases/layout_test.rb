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

  class UserResourceWithInlineLayoutReturningString < UserResource
    layout inline: proc {
      %({"header":"my header", "body": #{serialized_json}})
    }
  end

  def test_it_renders_json_within_inline_layout_returning_string
    assert_equal(
      {'header' => 'my header', 'body' => {'id' => 1, 'name' => 'Masafumi OKURA'}}, # rubocop:disable Style/StringHashKeys
      JSON.parse(UserResourceWithInlineLayoutReturningString.new(@user).serialize)
    )
  end

  class UserResourceWithInlineLayoutReturningHash < UserResource
    layout inline: proc {
      {header: 'my header', body: serializable_hash}
    }
  end

  def test_it_renders_json_within_inline_layout_returning_hash
    assert_equal(
      {'header' => 'my header', 'body' => {'id' => 1, 'name' => 'Masafumi OKURA'}}, # rubocop:disable Style/StringHashKeys
      JSON.parse(UserResourceWithInlineLayoutReturningHash.new(@user).serialize)
    )
  end

  def test_it_raises_exception_when_file_layout_is_not_a_string
    error = assert_raises(ArgumentError) do
      Class.new(UserResource) do
        layout file: 42
      end
    end
    assert_equal 'File layout must be a String representing filename', error.message
  end

  def test_it_raises_exception_when_inline_layout_is_not_a_proc
    error = assert_raises(ArgumentError) do
      Class.new(UserResource) do
        layout inline: 42
      end
    end
    assert_equal 'Inline layout must be a Proc returning a Hash or a String', error.message
  end

  def test_it_raises_exception_when_inline_layout_is_a_proc_but_returns_wrong_type
    klass = Class.new(UserResource) do
      layout inline: proc { 42 }
    end
    error = assert_raises(Alba::Error) do
      klass.new(@user).serialize
    end
    assert_equal 'Inline layout must be a Proc returning a Hash or a String', error.message
  end
end
