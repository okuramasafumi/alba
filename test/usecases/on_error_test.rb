# frozen_string_literal: true

require_relative '../test_helper'

class OnErrorTest < Minitest::Test
  class User
    attr_accessor :id, :name, :created_at, :updated_at

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
      @created_at = Time.now
      @updated_at = Time.now
    end

    # rubocop:disable Style/RedundantException
    def email
      raise RuntimeError, 'Error!'
    end
    # rubocop:enable Style/RedundantException
  end

  class UserResource
    include Alba::Resource

    root_key :user

    attributes :id, :name, :email
  end

  class UserResource1 < UserResource
    on_error :raise
  end

  class UserResource2 < UserResource
    on_error :ignore
  end

  class UserResource3 < UserResource
    on_error :nullify
  end

  class UserResource4 < UserResource
    on_error do |error, _, key|
      [key, error.message]
    end
  end

  class UserResource5 < UserResource
    on_error :ignore
  end

  class UserResourceToChangeErrorKey < UserResource
    on_error do |error|
      ['error', error.message]
    end
  end

  class UserResourceForProcIgnoreKey < UserResource
    on_error do |_error|
      Alba::REMOVE_KEY
    end
  end

  def setup
    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
  end

  def test_on_error_default
    assert_raises RuntimeError do
      UserResource.new(@user).serialize
    end
  end

  def test_on_error_raise
    assert_raises RuntimeError do
      UserResource1.new(@user).serialize
    end
  end

  def test_on_error_ignore
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA"}}',
      UserResource2.new(@user).serialize
    )
  end

  def test_on_error_nullify
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","email":null}}',
      UserResource3.new(@user).serialize
    )
  end

  def test_on_error_block
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","email":"Error!"}}',
      UserResource4.new(@user).serialize
    )
  end

  def test_on_error_invalid
    assert_raises Alba::Error do
      Class.new(UserResource) do
        on_error :invalid
      end
    end
  end

  def test_on_error_both_handler_and_block_provided
    assert_raises ArgumentError do
      Class.new(UserResource) do
        def self.name
          'UserResource7'
        end

        on_error :both do |error|
          p error
        end
      end
    end
  end

  def test_on_error_without_handler_and_block
    assert_raises ArgumentError do
      Class.new(UserResource) do
        def self.name
          'UserResource8'
        end

        on_error
      end
    end
  end

  def test_on_error_block_that_changes_key
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","error":"Error!"}}',
      UserResourceToChangeErrorKey.new(@user).serialize
    )
  end

  def test_on_error_proc_ignore
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA"}}',
      UserResourceForProcIgnoreKey.new(@user).serialize
    )
  end
end
