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

  class BankAccountResource
    include Alba::Resource

    key!

    attributes :account_number
    transform_keys :dash
  end

  class BankAccountRootResource < BankAccountResource
    transform_keys :lower_camel, root: true
  end

  class BankAccountRootFalseResource < BankAccountResource
    transform_keys :dash, root: false
  end

  class CustomInflector
    def camelize(key)
      "camelized_#{key}"
    end
  end

  def setup
    Alba.enable_inference!

    @user = User.new(1, 'Masafumi', 'Okura')
    @bank_account = BankAccount.new(123_456_789)
  end

  def teardown
    Alba.disable_inference!
    Alba.disable_root_key_transformation!
    Alba.inflector = nil
  end

  def test_alba_error_is_raised_in_the_code_load_phase_if_key_transforms_setting_is_not_known
    err = assert_raises(Alba::Error) {
      Class.new(UserResource) do
        transform_keys :unknown
      end
    }
    assert_equal(
      err.message,
      "Unknown transform_type: unknown. Supported transform_type are :camel, :lower_camel and :dash."
    )
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

  def test_transform_key_to_dash_with_key_inference_does_not_work_on_root_key_when_global_root_key_transformation_disabled
    assert_equal(
      '{"bank_account":{"account-number":123456789}}',
      BankAccountResource.new(@bank_account).serialize
    )
  end

  def test_transform_key_to_dash_with_key_inference_works_on_root_key_when_global_root_key_transformation_enabled
    Alba.enable_root_key_transformation!
    assert_equal(
      '{"bank-account":{"account-number":123456789}}',
      BankAccountResource.new(@bank_account).serialize
    )
  end

  def test_transform_key_to_dash_with_key_inference_does_not_work_on_root_key_when_global_root_key_transformation_enabled_but_root_option_set_to_false
    Alba.enable_root_key_transformation!
    assert_equal(
      '{"bank_account_root_false":{"account-number":123456789}}',
      BankAccountRootFalseResource.new(@bank_account).serialize
    )
  end

  def test_transform_key_to_lower_camel_works_on_root_key_when_root_option_set_to_true
    assert_equal(
      '{"bankAccountRoot":{"accountNumber":123456789}}',
      BankAccountRootResource.new(@bank_account).serialize
    )
  end

  def test_custom_inflector_is_used_if_defined
    Alba.inflector = CustomInflector.new
    assert_equal(
      '{"camelized_id":1,"camelized_first_name":"Masafumi","camelized_last_name":"Okura"}',
      UserResourceCamel.new(@user).serialize
    )
  end

end