require_relative '../test_helper'

class KeyTransformTest < Minitest::Test
  class User
    attr_reader :id, :first_name, :last_name

    def initialize(id, first_name, last_name)
      @id = id
      @first_name = first_name
      @last_name = last_name
    end
  end

  class BankAccount
    attr_reader :account_number

    def initialize(account_number)
      @account_number = account_number
    end
  end

  class UserResource
    include Alba::Resource

    attributes :id, :first_name, :last_name
  end

  class UserResourceCamel < UserResource
    transform_keys :camel
  end

  class UserResourceLowerCamel < UserResource
    transform_keys :lower_camel
  end

  class UserResourceDash < UserResource
    transform_keys :dash
  end

  class UserResourceUnknown < UserResource
    transform_keys :unknown
  end

  class BankAccountResource
    include Alba::Resource

    key!

    attributes :account_number
    transform_keys :dash
  end

  def setup
    Alba.enable_inference!

    @user = User.new(1, 'Masafumi', 'Okura')
    @bank_account = BankAccount.new(123456789)
  end

  def teardown
    Alba.disable_inference!
  end

  def test_transform_key_to_camel
    assert_equal(
      '{"Id":1,"FirstName":"Masafumi","LastName":"Okura"}',
      UserResourceCamel.new(@user).serialize
    )
  end

  def test_transform_key_to_lower_camel
    assert_equal(
      '{"id":1,"firstName":"Masafumi","lastName":"Okura"}',
      UserResourceLowerCamel.new(@user).serialize
    )
  end

  def test_transform_key_to_dash
    assert_equal(
      '{"id":1,"first-name":"Masafumi","last-name":"Okura"}',
      UserResourceDash.new(@user).serialize
    )
  end

  def test_transform_key_to_dash_with_key_inference
    assert_equal(
      '{"bank-account":{"account-number":123456789}}',
      BankAccountResource.new(@bank_account).serialize
    )
  end

  def test_transform_key_to_unknown
    assert_raises(Alba::Error) { UserResourceUnknown.new(@user).serialize }
  end
end
