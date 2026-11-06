# frozen_string_literal: true

require_relative '../test_helper'
require 'timeout'

class LayoutTest < Minitest::Test
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

  def test_inline_layout_returning_string_is_isolated_between_threads
    assert_inline_layout_is_isolated_between_threads(:string)
  end

  def test_inline_layout_returning_hash_is_isolated_between_threads
    assert_inline_layout_is_isolated_between_threads(:hash)
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

  def test_it_raises_exception_when_layout_has_no_arguments
    error = assert_raises(ArgumentError) do
      Class.new(UserResource) do
        layout
      end
    end
    assert_equal 'Layout must be either String or Proc', error.message
  end

  private

  def assert_inline_layout_is_isolated_between_threads(return_type)
    entered = Queue.new
    resume = Queue.new
    klass = Class.new(UserResource) do
      layout inline: proc {
        if params[:pause]
          entered << true
          resume.pop
        end
        result = {
          object: object.id,
          params: params[:id],
          serializable_hash: serializable_hash.fetch('id'),
          to_h: to_h.fetch('id'),
          serialized_json: JSON.parse(serialized_json).fetch('id')
        }
        return_type == :string ? JSON.generate(result) : result
      }
    end
    other_user = User.new(2, 'Other user', 'other@example.com')
    first = klass.new(@user, params: {id: 1, pause: true})
    second = klass.new(other_user, params: {id: 2})
    workers = []

    Timeout.timeout(5) do
      workers << Thread.new { first.serialize }
      entered.pop # A is inside the layout before B starts serializing.
      workers << Thread.new { second.serialize }
      second_result = JSON.parse(workers.last.value)
      resume << true # B has finished; A now reads its layout context.
      first_result = JSON.parse(workers.first.value)

      keys = %w[object params serializable_hash to_h serialized_json]
      assert_equal keys.to_h { |key| [key, 2] }, second_result
      assert_equal keys.to_h { |key| [key, 1] }, first_result
    end
  ensure
    workers&.each { |worker| worker.kill if worker.alive? }
    workers&.each(&:join)
  end
end
