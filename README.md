![alba card](https://raw.githubusercontent.com/okuramasafumi/alba/main/logo/alba-card.png)
----------
[![Gem Version](https://badge.fury.io/rb/alba.svg)](https://badge.fury.io/rb/alba)
[![CI](https://github.com/okuramasafumi/alba/actions/workflows/main.yml/badge.svg)](https://github.com/okuramasafumi/alba/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/okuramasafumi/alba/branch/main/graph/badge.svg?token=3D3HEZ5OXT)](https://codecov.io/gh/okuramasafumi/alba)
[![Maintainability](https://api.codeclimate.com/v1/badges/fdab4cc0de0b9addcfe8/maintainability)](https://codeclimate.com/github/okuramasafumi/alba/maintainability)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/okuramasafumi/alba)
![GitHub](https://img.shields.io/github/license/okuramasafumi/alba)

# Alba

Alba is a JSON serializer for Ruby, JRuby, and TruffleRuby.

## Discussions

Alba uses [GitHub Discussions](https://github.com/okuramasafumi/alba/discussions) to openly discuss the project.

If you've already used Alba, please consider posting your thoughts and feelings on [Feedback](https://github.com/okuramasafumi/alba/discussions/categories/feedback). The fact that you enjoy using Alba gives me energy to keep developing Alba!

If you have feature requests or interesting ideas, join us with [Ideas](https://github.com/okuramasafumi/alba/discussions/categories/ideas). Let's make Alba even better, together!

## Resources

If you want to know more about Alba, there's a [screencast](https://hanamimastery.com/episodes/21-serialization-with-alba) created by Sebastian from [Hanami Mastery](https://hanamimastery.com/). It covers basic features of Alba and how to use it in Hanami.

## Why Alba?

Because it's fast, easy and feature rich!

### Fast

Alba is faster than most of the alternatives. We have a [benchmark](https://github.com/okuramasafumi/alba/tree/main/benchmark).

### Easy

Alba is easy to use because there are only a few methods to remember. It's also easy to understand due to clean and short codebase. Finally it's easy to extend since it provides some methods for override to change default behavior of Alba.

### Feature rich

While Alba's core is simple, it provides additional features when you need them, For example, Alba provides [a way to control circular associations](#circular-associations-control), [root key and association resource name inference](#root-key-and-association-resource-name-inference) and [supports layouts](#layout).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alba'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install alba

## Supported Ruby versions

Alba supports CRuby 2.6 and higher and latest JRuby and TruffleRuby.

## Documentation

You can find the documentation on [RubyDoc](https://rubydoc.info/github/okuramasafumi/alba).

## Features

* Conditional attributes and associations
* Selectable backend
* Key transformation
* Root key and association resource name inference
* Error handling
* Nil handling
* Circular associations control
* [Experimental] Types for validation and conversion
* Layout
* No runtime dependencies

## Usage

### Configuration

Alba's configuration is fairly simple.

#### Backend configuration

Backend is the actual part serializing an object into JSON. Alba supports these backends.

|name|description|requires_external_gem|
|--|--|--|
|`oj`, `oj_strict`|Using Oj in `strict` mode|Yes(C extension)|
|`oj_rails`|It's `oj` but in `rails` mode|Yes(C extension)|
|`oj_default`|It's `oj` but respects mode set by users|Yes(C extension)|
|`active_support`|For Rails compatibility|Yes|
|`default`, `json`|Using `json` gem|No|

You can set a backend like this:

```ruby
Alba.backend = :oj
```

#### Encoder configuration

You can also set JSON encoder directly with a Proc.

```ruby
Alba.encoder = ->(object) { JSON.generate(object) }
```

You can consider setting a backend with Symbol as a shortcut to set encoder.

#### Inference configuration

You can enable the inference feature using the `Alba.inflector = SomeInflector` API. For example, in a Rails initializer:

```ruby
Alba.inflector = :active_support
```

You can choose which inflector Alba uses for inference. Possible options are:

- `:active_support` for `ActiveSupport::Inflector`
- `:dry` for `Dry::Inflector`
- any object which conforms to the protocol (see [below](#custom-inflector))

To disable inference, set the `inflector` to `nil`:

```ruby
Alba.inflector = nil
```

To check if inference is enabled etc, inspect the return value of `inflector`:

```ruby
if Alba.inflector == nil
  puts "inflector not set"
else
  puts "inflector is set to #{Alba.inflector}"
end
```

### Simple serialization with root key

You can define attributes with (yes) `attributes` macro with attribute names. If your attribute need some calculations, you can use `attribute` with block.

```ruby
class User
  attr_accessor :id, :name, :email, :created_at, :updated_at
  def initialize(id, name, email)
    @id = id
    @name = name
    @email = email
    @created_at = Time.now
    @updated_at = Time.now
  end
end

class UserResource
  include Alba::Resource

  root_key :user

  attributes :id, :name

  attribute :name_with_email do |resource|
    "#{resource.name}: #{resource.email}"
  end
end

user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
UserResource.new(user).serialize
# => '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}'
```

You can define instance methods on resources so that you can use it as attribute name in `attributes`.

```ruby
# The serialization result is the same as above
class UserResource
  include Alba::Resource

  root_key :user, :users # Later is for plural

  attributes :id, :name, :name_with_email

  # Attribute methods must accept one argument for each serialized object
  def name_with_email(user)
    "#{user.name}: #{user.email}"
  end
end
```

This even works with users collection.

```ruby
user1 = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
user2 = User.new(2, 'Test User', 'test@example.com')
UserResource.new([user1, user2]).serialize
# => '{"users":[{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"},{"id":2,"name":"Test User","name_with_email":"Test User: test@example.com"}]}'
```

If you have a simple case where you want to change only the name, you can use the Symbol to Proc shortcut:

```ruby
class UserResource
  include Alba::Resource

  attribute :some_other_name, &:name
end
```

#### Params

You can pass a Hash to the resource for internal use. It can be used as "flags" to control attribute content.

```ruby
class UserResource
  include Alba::Resource
  attribute :name do |user|
    params[:upcase] ? user.name.upcase : user.name
  end
end

user = User.new(1, 'Masa', 'test@example.com')
UserResource.new(user).serialize # => '{"name":"Masa"}'
UserResource.new(user, params: {upcase: true}).serialize # => '{"name":"MASA"}'
```

### Serialization with associations

Associations can be defined using the `association` macro, which is also aliased as `one`, `many`, `has_one`, and `has_many` for convenience.

```ruby
class User
  attr_reader :id, :created_at, :updated_at
  attr_accessor :articles

  def initialize(id)
    @id = id
    @created_at = Time.now
    @updated_at = Time.now
    @articles = []
  end
end

class Article
  attr_accessor :user_id, :title, :body

  def initialize(user_id, title, body)
    @user_id = user_id
    @title = title
    @body = body
  end
end

class ArticleResource
  include Alba::Resource

  attributes :title
end

class UserResource
  include Alba::Resource

  attributes :id

  many :articles, resource: ArticleResource
end

user = User.new(1)
article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
user.articles << article1
article2 = Article.new(2, 'Super nice', 'Really nice!')
user.articles << article2

UserResource.new(user).serialize
# => '{"id":1,"articles":[{"title":"Hello World!"},{"title":"Super nice"}]}'
```

You can define associations inline if you don't need a class for association.

```ruby
class ArticleResource
  include Alba::Resource

  attributes :title
end

class UserResource
  include Alba::Resource

  attributes :id

  many :articles, resource: ArticleResource
end

# This class works the same as `UserResource`
class AnotherUserResource
  include Alba::Resource

  attributes :id

  many :articles do
    attributes :title
  end
end
```

You can "filter" association using second proc argument. This proc takes association object, `params` and initial object.

This feature is useful when you want to modify association, such as adding `includes` or `order` to ActiveRecord relations.

```ruby
class User
  attr_reader :id, :banned
  attr_accessor :articles

  def initialize(id, banned = false)
    @id = id
    @banned = banned
    @articles = []
  end
end

class Article
  attr_accessor :id, :title, :body

  def initialize(id, title, body)
    @id = id
    @title = title
    @body = body
  end
end

class ArticleResource
  include Alba::Resource

  attributes :title
end

class UserResource
  include Alba::Resource

  attributes :id

  # Second proc works as a filter
  many :articles,
    proc { |articles, params, user|
      filter = params[:filter] || :odd?
      articles.select {|a| a.id.send(filter) && !user.banned  }
    },
    resource: ArticleResource
end

user = User.new(1)
article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
user.articles << article1
article2 = Article.new(2, 'Super nice', 'Really nice!')
user.articles << article2

UserResource.new(user).serialize
# => '{"id":1,"articles":[{"title":"Hello World!"}]}'
UserResource.new(user, params: {filter: :even?}).serialize
# => '{"id":1,"articles":[{"title":"Super nice"}]}'
```

You can change a key for association with `key` option.

```ruby
class UserResource
  include Alba::Resource

  attributes :id

  many :articles,
    key: 'my_articles', # Set key here
    resource: ArticleResource
end
UserResource.new(user).serialize
# => '{"id":1,"my_articles":[{"title":"Hello World!"}]}'
```

You can omit the resource option if you enable Alba's [inference](#inference-configuration) feature.

```ruby
Alba.inflector = :active_support

class UserResource
  include Alba::Resource

  attributes :id

  many :articles # Using `ArticleResource`
end
UserResource.new(user).serialize
# => '{"id":1,"my_articles":[{"title":"Hello World!"}]}'
```

If you need complex logic to determine what resource to use for association, you can use a Proc for resource option.

```ruby
class UserResource
  include Alba::Resource

  attributes :id

  many :articles, ->(article) { article.with_comment? ? ArticleWithCommentResource : ArticleResource }
end
```

Note that using a Proc slows down serialization if there are too `many` associated objects.

#### Params override

Associations can override params. This is useful when associations are deeply nested.

```ruby
class BazResource
  include Alba::Resource

  attributes :data
  attributes :secret, if: proc { params[:expose_secret] }
end

class BarResource
  include Alba::Resource

  one :baz, resource: BazResource
end

class FooResource
  include Alba::Resource

  root_key :foo

  one :bar, resource: BarResource
end

class FooResourceWithParamsOverride
  include Alba::Resource

  root_key :foo

  one :bar, resource: BarResource, params: { expose_secret: false }
end

Baz = Struct.new(:data, :secret)
Bar = Struct.new(:baz)
Foo = Struct.new(:bar)

foo = Foo.new(Bar.new(Baz.new(1, 'secret')))
FooResource.new(foo, params: {expose_secret: true}).serialize # => '{"foo":{"bar":{"baz":{"data":1,"secret":"secret"}}}}'
FooResourceWithParamsOverride.new(foo, params: {expose_secret: true}).serialize # => '{"foo":{"bar":{"baz":{"data":1}}}}'
```

### Nested Attribute

Alba supports nested attributes that makes it easy to build complex data structure from single object.

In order to define nested attributes, you can use `nested` or `nested_attribute` (alias of `nested`).

```ruby
class User
  attr_accessor :id, :name, :email, :city, :zipcode

  def initialize(id, name, email, city, zipcode)
    @id = id
    @name = name
    @email = email
    @city = city
    @zipcode = zipcode
  end
end

class UserResource
  include Alba::Resource

  root_key :user

  attributes :id

  nested_attribute :address do
    attributes :city, :zipcode
  end
end

user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com', 'Tokyo', '0000000')
UserResource.new(user).serialize
# => '{"user":{"id":1,"address":{"city":"Tokyo","zipcode":"0000000"}}}'
```

Nested attributes can be nested deeply.

```ruby
class FooResource
  include Alba::Resource

  root_key :foo

  nested :bar do
    nested :baz do
      attribute :deep do
        42
      end
    end
  end
end

FooResource.new(nil).serialize
# => '{"foo":{"bar":{"baz":{"deep":42}}}}'
```

### Inline definition with `Alba.serialize`

`Alba.serialize` method is a shortcut to define everything inline.

```ruby
Alba.serialize(user, root_key: :foo) do
  attributes :id
  many :articles do
    attributes :title, :body
  end
end
# => '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}'
```

`Alba.serialize` can be used when you don't know what kind of object you serialize. For example:

```ruby
Alba.serialize(something)
# => Same as `FooResource.new(something).serialize` when `something` is an instance of `Foo`.
```

Although this might be useful sometimes, it's generally recommended to define a class for Resource.

### Serializable Hash

Instead of serializing to JSON, you can also output a Hash by calling `serializable_hash` or the `to_h` alias. Note also that the `serialize` method is aliased as `to_json`.

```ruby
# These are equivalent and will return serialized JSON
UserResource.new(user).serialize
UserResource.new(user).to_json

# These are equivalent and will return a Hash
UserResource.new(user).serializable_hash
UserResource.new(user).to_h
```

If you want a Hash that corresponds to a JSON String returned by `serialize` method, you can use `as_json`.

```ruby
# These are equivalent and will return the same result
UserResource.new(user).serialize
UserResource.new(user).to_json
JSON.generate(UserResource.new(user).as_json)
```

### Inheritance

When you include `Alba::Resource` in your class, it's just a class so you can define any class that inherits from it. You can add new attributes to inherited class like below:

```ruby
class FooResource
  include Alba::Resource

  root_key :foo

  attributes :bar
end

class ExtendedFooResource < FooResource
  root_key :foofoo

  attributes :baz
end

Foo = Struct.new(:bar, :baz)
foo = Foo.new(1, 2)
FooResource.new(foo).serialize # => '{"foo":{"bar":1}}'
ExtendedFooResource.new(foo).serialize # => '{"foofoo":{"bar":1,"baz":2}}'
```

In this example we add `baz` attribute and change `root_key`. This way, you can extend existing resource classes just like normal OOP. Don't forget that when your inheritance structure is too deep it'll become difficult to modify existing classes.

### Filtering attributes

Filtering attributes can be done in two ways - with `attributes` and `select`. They have different semantics and usage.

`select` is a new and more intuitive API, so generally it's recommended to use `select`.

#### Filtering attributes with `attributes`

You can filter out certain attributes by overriding `attributes` instance method. This is useful when you want to customize existing resource with inheritance.

You can access raw attributes via `super` call. It returns a Hash whose keys are the name of the attribute and whose values are the body. Usually you need only keys to filter out, like below.

```ruby
class Foo
  attr_accessor :id, :name, :body

  def initialize(id, name, body)
    @id = id
    @name = name
    @body = body
  end
end

class GenericFooResource
  include Alba::Resource

  attributes :id, :name, :body
end

class RestrictedFooResource < GenericFooResource
  def attributes
    super.select { |key, _| key.to_sym == :name }
  end
end

foo = Foo.new(1, 'my foo', 'body')

RestrictedFooResource.new(foo).serialize
# => '{"name":"my foo"}'
```

#### Filtering attributes with `select`

When you want to filter attributes based on more complex logic, you can use `select` instance method. `select` takes two parameters, the name of an attribute and the value of an attribute. If it returns false that attribute is rejected.

```ruby
class Foo
  attr_accessor :id, :name, :body

  def initialize(id, name, body)
    @id = id
    @name = name
    @body = body
  end
end

class GenericFooResource
  include Alba::Resource

  attributes :id, :name, :body
end

class RestrictedFooResource < GenericFooResource
  def select(_key, value)
    !value.nil?
  end
end

foo = Foo.new(1, nil, 'body')

RestrictedFooResource.new(foo).serialize
# => '{"id":1,"body":"body"}'
```

### Key transformation

If you have [inference](#inference-configuration) enabled, you can use the `transform_keys` DSL to transform attribute keys.

```ruby
Alba.inflector = :active_support

class User
  attr_reader :id, :first_name, :last_name

  def initialize(id, first_name, last_name)
    @id = id
    @first_name = first_name
    @last_name = last_name
  end
end

class UserResource
  include Alba::Resource

  attributes :id, :first_name, :last_name

  transform_keys :lower_camel
end

user = User.new(1, 'Masafumi', 'Okura')
UserResourceCamel.new(user).serialize
# => '{"id":1,"firstName":"Masafumi","lastName":"Okura"}'
```

Possible values for `transform_keys` argument are:

* `:camel` for CamelCase
* `:lower_camel` for lowerCamelCase
* `:dash` for dash-case
* `:snake` for snake_case
* `:none` for not transforming keys

#### Root key transformation

You can also transform root key when:

* `Alba.inflector` is set
* `root_key!` is called in Resource class
* `root` option of `transform_keys` is set to true

```ruby
Alba.inflector = :active_support

class BankAccount
  attr_reader :account_number

  def initialize(account_number)
    @account_number = account_number
  end
end

class BankAccountResource
  include Alba::Resource

  root_key!

  attributes :account_number
  transform_keys :dash, root: true
end

bank_account = BankAccount.new(123_456_789)
BankAccountResource.new(bank_account).serialize
# => '{"bank-account":{"account-number":123456789}}'
```

This is the default behavior from version 2.

Find more details in the [Inference configuration](#inference-configuration) section.

#### Key transformation cascading

When you use `transform_keys` with inline association, it automatically applies the same transformation type to those inline association.

This is the default behavior from version 2, but you can do the same thing with adding `transform_keys` to each association.

You can also turn it off by setting `cascade: false` option to `transform_keys`.

```ruby
class User
  attr_reader :id, :first_name, :last_name, :bank_account

  def initialize(id, first_name, last_name)
    @id = id
    @first_name = first_name
    @last_name = last_name
    @bank_account = BankAccount.new(1234)
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

  transform_keys :lower_camel # Default is cascade: true

  one :bank_account do
    attributes :account_number
  end
end

user = User.new(1, 'Masafumi', 'Okura')
UserResource.new(user).serialize
# => '{"id":1,"firstName":"Masafumi","lastName":"Okura","bankAccount":{"accountNumber":1234}}'
```

#### Custom inflector

A custom inflector can be plugged in as follows.

```ruby
module CustomInflector
  module_function

  def camelize(string)
  end

  def camelize_lower(string)
  end

  def dasherize(string)
  end

  def underscore(string)
  end

  def classify(string)
  end
end

Alba.inflector = CustomInflector
```

### Conditional attributes

Filtering attributes with overriding `attributes` works well for simple cases. However, It's cumbersome when we want to filter various attributes based on different conditions for keys.

In these cases, conditional attributes works well. We can pass `if` option to `attributes`, `attribute`, `one` and `many`. Below is an example for the same effect as [filtering attributes section](#filtering-attributes).

```ruby
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

  attributes :id, :name, :email, if: proc { |user, attribute| !attribute.nil? }
end

user = User.new(1, nil, nil)
UserResource.new(user).serialize # => '{"id":1}'
```

### Default

Alba doesn't support default value for attributes, but it's easy to set a default value.

```ruby
class FooResource
  attribute :bar do |foo|
    foo.bar || 'default bar'
  end
end
```

We believe this is clearer than using some (not implemented yet) DSL such as `default` because there are some conditions where default values should be applied (`nil`, `blank?`, `empty?` etc.)

### Root key and association resource name inference

If [inference](#inference-configuration) is enabled, Alba tries to infer the root key and association resource names.

```ruby
Alba.inflector = :active_support

class User
  attr_reader :id
  attr_accessor :articles

  def initialize(id)
    @id = id
    @articles = []
  end
end

class Article
  attr_accessor :id, :title

  def initialize(id, title)
    @id = id
    @title = title
  end
end

class ArticleResource
  include Alba::Resource

  attributes :title
end

class UserResource
  include Alba::Resource

  root_key!

  attributes :id

  many :articles
end

user = User.new(1)
user.articles << Article.new(1, 'The title')

UserResource.new(user).serialize # => '{"user":{"id":1,"articles":[{"title":"The title"}]}}'
UserResource.new([user]).serialize # => '{"users":[{"id":1,"articles":[{"title":"The title"}]}]}'
```

This resource automatically sets its root key to either "users" or "user", depending on the given object is collection or not.

Also, you don't have to specify which resource class to use with `many`. Alba infers it from association name.

Find more details in the [Inference configuration](#inference-configuration) section.

### Error handling

You can set error handler globally or per resource using `on_error`.

```ruby
class User
  attr_accessor :id, :name

  def initialize(id, name, email)
    @id = id
    @name = name
    @email = email
  end

  def email
    raise RuntimeError, 'Error!'
  end
end

class UserResource
  include Alba::Resource

  attributes :id, :name, :email

  on_error :ignore
end

user = User.new(1, 'Test', 'email@example.com')
UserResource.new(user).serialize # => '{"id":1,"name":"Test"}'
```

This way you can exclude an entry when fetching an attribute gives an exception.

There are four possible arguments `on_error` method accepts.

* `:raise` re-raises an error. This is the default behavior.
* `:ignore` ignores the entry with the error.
* `:nullify` sets the attribute with the error to `nil`.
* Block gives you more control over what to be returned.

The block receives five arguments, `error`, `object`, `key`, `attribute` and `resource class` and must return a two-element array. Below is an example.

```ruby
class ExampleResource
  include Alba::Resource
  on_error do |error, object, key, attribute, resource_class|
    if resource_class == MyResource
      ['error_fallback', object.error_fallback]
    else
      [key, error.message]
    end
  end
end
```

### Nil handling

Sometimes we want to convert `nil` to different values such as empty string. Alba provides a flexible way to handle `nil`.

```ruby
class User
  attr_reader :id, :name, :age

  def initialize(id, name = nil, age = nil)
    @id = id
    @name = name
    @age = age
  end
end

class UserResource
  include Alba::Resource

  on_nil { '' }

  root_key :user, :users

  attributes :id, :name, :age
end

UserResource.new(User.new(1)).serialize
# => '{"user":{"id":1,"name":"","age":""}}'
```

You can get various information via block parameters.

```ruby
class UserResource
  include Alba::Resource

  on_nil do |object, key|
    if key == 'age'
      20
    else
      "User#{object.id}"
    end
  end

  root_key :user, :users

  attributes :id, :name, :age
end

UserResource.new(User.new(1)).serialize
# => '{"user":{"id":1,"name":"User1","age":20}}'
```

### Metadata

You can set a metadata with `meta` DSL or `meta` option.

```ruby
class UserResource
  include Alba::Resource

  root_key :user, :users

  attributes :id, :name

  meta do
    if object.is_a?(Enumerable)
      {size: object.size}
    else
      {foo: :bar}
    end
  end
end

user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
UserResource.new([user]).serialize
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}],"meta":{"size":1}}'

# You can merge metadata with `meta` option

UserResource.new([user]).serialize(meta: {foo: :bar})
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}],"meta":{"size":1,"foo":"bar"}}'

# You can set metadata with `meta` option alone

class UserResourceWithoutMeta
  include Alba::Resource

  root_key :user, :users

  attributes :id, :name
end

UserResourceWithoutMeta.new([user]).serialize(meta: {foo: :bar})
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}],"meta":{"foo":"bar"}}'
```

You can use `object` method to access the underlying object and `params` to access the params in `meta` block.

Note that setting root key is required when setting a metadata.

### Circular associations control

**Note that this feature works correctly since version 1.3. In previous versions it doesn't work as expected.**

You can control circular associations with `within` option. `within` option is a nested Hash such as `{book: {authors: books}}`. In this example, Alba serializes a book's authors' books. This means you can reference `BookResource` from `AuthorResource` and vice versa. This is really powerful when you have a complex data structure and serialize certain parts of it.

For more details, please refer to [test code](https://github.com/okuramasafumi/alba/blob/main/test/usecases/circular_association_test.rb)

### Experimental support of types

You can validate and convert input with types.

```ruby
class User
  attr_reader :id, :name, :age, :bio, :admin, :created_at

  def initialize(id, name, age, bio = '', admin = false) # rubocop:disable Style/OptionalBooleanParameter
    @id = id
    @name = name
    @age = age
    @admin = admin
    @bio = bio
    @created_at = Time.new(2020, 10, 10)
  end
end

class UserResource
  include Alba::Resource

  attributes :name, id: [String, true], age: [Integer, true], bio: String, admin: [:Boolean, true], created_at: [String, ->(object) { object.strftime('%F') }]
end

user = User.new(1, 'Masafumi OKURA', '32', 'Ruby dev')
UserResource.new(user).serialize
# => '{"name":"Masafumi OKURA","id":"1","age":32,"bio":"Ruby dev","admin":false,"created_at":"2020-10-10"}'
```

Notice that `id` and `created_at` are converted to String and `age` is converted to Integer.

If type is not correct and auto conversion is disabled (default), `TypeError` occurs.

```ruby
user = User.new(1, 'Masafumi OKURA', '32', nil) # bio is nil and auto conversion is disabled for bio
UserResource.new(user).serialize
# => TypeError, 'Attribute bio is expected to be String but actually nil.'
```

Note that this feature is experimental and interfaces are subject to change.

### Collection serialization into Hash

Sometimes we want to serialize a collection into a Hash, not an Array. It's possible with Alba.

```ruby
class User
  attr_reader :id, :name
  def initialize(id, name)
    @id, @name = id, name
  end
end

class UserResource
  include Alba::Resource

  collection_key :id # This line is important

  attributes :id, :name
end

user1 = User.new(1, 'John')
user2 = User.new(2, 'Masafumi')

UserResource.new([user1, user2]).serialize
# => '{"1":{"id":1,"name":"John"},"2":{"id":2,"name":"Masafumi"}}'
```

In the snippet above, `collection_key :id` specifies the key used for the key of the collection hash. In this example it's `:id`.

Make sure that collection key is unique for the collection.

### Layout

Sometimes we'd like to serialize JSON into a template. In other words, we need some structure OUTSIDE OF serialized JSON. IN HTML world, we call it a "layout".

Alba supports serializing JSON in a layout. You need a file for layout and then to specify file with `layout` method.

```erb
{
  "header": "my_header",
  "body": <%= serialized_json %>
}
```

```ruby
class FooResource
  include Alba::Resource
  layout file: 'my_layout.json.erb'
end
```

Note that layout files are treated as `json` and `erb` and evaluated in a context of the resource, meaning

* A layout file must be a valid JSON
* You must write `<%= serialized_json %>` in a layout to put serialized JSON string into a layout
* You can access `params` in a layout so that you can add virtually any objects to a layout
  * When you access `params`, it's usually a Hash. You can use `encode` method in a layout to convert `params` Hash into a JSON with the backend you use
* You can also access `object`, the underlying object for the resource

In case you don't want to have a file for layout, Alba lets you define and apply layouts inline:

```ruby
class FooResource
  include Alba::Resource
  layout inline: proc do
    {
      header: 'my header',
      body: serializable_hash
    }
  end
end
```

In the example above, we specify a Proc which returns a Hash as an inline layout. In the Proc we can use `serializable_hash` method to access a Hash right before serialization.

You can also use a Proc which returns String, not a Hash, for an inline layout.

```ruby
class FooResource
  include Alba::Resource
  layout inline: proc do
    %({
      "header": "my header",
      "body": #{serialized_json}
    })
  end
end
```

It looks similar to file layout but you must use string interpolation for method calls since it's not an ERB.

Also note that we use percentage notation here to use double quotes. Using single quotes in inline string layout causes the error which might be resolved in other ways.

### Caching

Currently, Alba doesn't support caching, primarily due to the behavior of `ActiveRecord::Relation`'s cache. See [the issue](https://github.com/rails/rails/issues/41784).

### Extend Alba

Sometimes we have shared behaviors across resources. In such cases we can have a module for common logic.

In `attribute` block we can call instance method so we can improve the code below:

```ruby
class FooResource
  include Alba::Resource
  # other attributes
  attribute :created_at do |foo|
    foo.created_at.strftime('%m/%d/%Y')
  end

  attribute :updated_at do |foo|
    foo.updated_at.strftime('%m/%d/%Y')
  end
end

class BarResource
  include Alba::Resource
  # other attributes
  attribute :created_at do |bar|
    bar.created_at.strftime('%m/%d/%Y')
  end

  attribute :updated_at do |bar|
    bar.updated_at.strftime('%m/%d/%Y')
  end
end
```

to:

```ruby
module SharedLogic
  def format_time(time)
    time.strftime('%m/%d/%Y')
  end
end

class FooResource
  include Alba::Resource
  include SharedLogic
  # other attributes
  attribute :created_at do |foo|
    format_time(foo.created_at)
  end

  attribute :updated_at do |foo|
    format_time(foo.updated_at)
  end
end

class BarResource
  include Alba::Resource
  include SharedLogic
  # other attributes
  attribute :created_at do |bar|
    format_time(bar.created_at)
  end

  attribute :updated_at do |bar|
    format_time(bar.updated_at)
  end
end
```

We can even add our own DSL to serialize attributes for readability and removing code duplications.

To do so, we need to `extend` our module. Let's see how we can achieve the same goal with this approach.

```ruby
module AlbaExtension
  # Here attrs are an Array of Symbol
  def formatted_time_attributes(*attrs)
    attrs.each do |attr|
      attribute attr do |object|
        time = object.send(attr)
        time.strftime('%m/%d/%Y')
      end
    end
  end
end

class FooResource
  include Alba::Resource
  extend AlbaExtension
  # other attributes
  formatted_time_attributes :created_at, :updated_at
end

class BarResource
  include Alba::Resource
  extend AlbaExtension
  # other attributes
  formatted_time_attributes :created_at, :updated_at
end
```

In this way we have shorter and cleaner code. Note that we need to use `send` or `public_send` in `attribute` block to get attribute data.

### Debugging

Debugging is not easy. If you find Alba not working as you expect, there are a few things to do:

1. Inspect

The typical code looks like this:

```ruby
class FooResource
  include Alba::Resource
  attributes :id
end
FooResource.new(foo).serialize
```

Notice that we instantiate `FooResource` and then call `serialize` method. We can get various information by calling `inspect` method on it.

```ruby
puts FooResource.new(foo).inspect # or: p class FooResource.new(foo)
# => "#<FooResource:0x000000010e21f408 @object=[#<Foo:0x000000010e3470d8 @id=1>], @params={}, @within=#<Object:0x000000010df2eac8>, @method_existence={}, @_attributes={:id=>:id}, @_key=nil, @_key_for_collection=nil, @_meta=nil, @_transform_type=:none, @_transforming_root_key=false, @_on_error=nil, @_on_nil=nil, @_layout=nil, @_collection_key=nil>"
```

The output might be different depending on the version of Alba or the object you give, but the concepts are the same. `@object` represents the object you gave as an argument to `new` method, `@_attributes` represents the attributes you defined in `FooResource` class using `attributes` DSL.

Other things are not so important, but you need to take care of corresponding part when you use additional features such as `root_key`, `transform_keys` and adding params.

2. Logging

Alba currently doesn't support logging directly, but you can add your own logging module to Alba easily.

```ruby
module Logging
  def serialize(...) # `...` was added in Ruby 2.7
    puts serializable_hash
    super(...)
  end
end

FooResource.prepend Logging
FooResource.new(foo).serialize
# => "{:id=>1}" is printed
```

Here, we override `serialize` method with `prepend`. In overridden method we print the result of `serializable_hash` that gives the basic hash for serialization to `serialize` method. Using `...` allows us to override without knowing method signiture of `serialize`.

Don't forget calling `super` in this way.

## Rails

When you use Alba in Rails, you can create an initializer file with the line below for compatibility with Rails JSON encoder.

```ruby
Alba.backend = :active_support
# or
Alba.backend = :oj_rails
```

To find out more details, please see https://github.com/okuramasafumi/alba/blob/main/docs/rails.md

## Why named "Alba"?

The name "Alba" comes from "albatross", a kind of birds. In Japanese, this bird is called "Aho-dori", which means "stupid bird". I find it funny because in fact albatrosses fly really fast. I hope Alba looks stupid but in fact it does its job quick.

## Pioneers

There are great pioneers in Ruby's ecosystem which does basically the same thing as Alba does. To name a few:

* [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers) a.k.a AMS, the most famous implementation of JSON serializer for Ruby
* [Blueprinter](https://github.com/procore/blueprinter) shares some concepts with Alba

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Thank you for begin interested in contributing to Alba! Please see [contributors guide](https://github.com/okuramasafumi/alba/blob/main/CONTRIBUTING.md) before start contributing. If you have any questions, please feel free to ask in [Discussions](https://github.com/okuramasafumi/alba/discussions).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Alba project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/okuramasafumi/alba/blob/main/CODE_OF_CONDUCT.md).
