![alba card](https://raw.githubusercontent.com/okuramasafumi/alba/main/logo/alba-card.png)
----------
[![Gem Version](https://badge.fury.io/rb/alba.svg)](https://badge.fury.io/rb/alba)
[![CI](https://github.com/okuramasafumi/alba/actions/workflows/main.yml/badge.svg)](https://github.com/okuramasafumi/alba/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/okuramasafumi/alba/branch/main/graph/badge.svg?token=3D3HEZ5OXT)](https://codecov.io/gh/okuramasafumi/alba)
[![Maintainability](https://qlty.sh/gh/okuramasafumi/projects/alba/maintainability.svg)](https://qlty.sh/gh/okuramasafumi/projects/alba)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/okuramasafumi/alba)
![GitHub](https://img.shields.io/github/license/okuramasafumi/alba)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

# Alba

Alba is a JSON serializer for Ruby, JRuby, and TruffleRuby.

## IMPORTANT NOTICE

Both version `3.0.0` and `2.4.2` contain important bug fix.
~~However, version `3.0.0` has some bugs (see https://github.com/okuramasafumi/alba/issues/342).
Until they get fixed, it's highly recommended to upgrade to version `2.4.2`.
Dependabot and similar tools might create an automated Pull Request to upgrade to `3.0.0`, so it might be required to upgrade to `2.4.2` manually.~~
Version `3.0.1` has been released so Ruby 3 users should upgrade to `3.0.1`.
For Ruby 2 users, it's highly recommended to upgrade to `2.4.2`.
Sorry for the inconvenience.

## TL;DR

Alba allows you to do something like below.

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

Seems useful? Continue reading!

## Discussions

Alba uses [GitHub Discussions](https://github.com/okuramasafumi/alba/discussions) to openly discuss the project.

If you've already used Alba, please consider posting your thoughts and feelings on [Feedback](https://github.com/okuramasafumi/alba/discussions/categories/feedback). The fact that you enjoy using Alba gives me energy to keep developing Alba!

If you have feature requests or interesting ideas, join us with [Ideas](https://github.com/okuramasafumi/alba/discussions/categories/ideas). Let's make Alba even better, together!

## Resources

If you want to know more about Alba, there's a [screencast](https://hanamimastery.com/episodes/21-serialization-with-alba) created by Sebastian from [Hanami Mastery](https://hanamimastery.com/). It covers basic features of Alba and how to use it in Hanami.

## What users say about Alba

> Alba is a well-maintained JSON serialization engine, for Ruby, JRuby, and TruffleRuby implementations, and what I like in this gem - except of its speed, is the easiness of use, no dependencies and the fact it plays well with any Ruby application!

[Hanami Mastery by Seb Wilgosz](https://hanamimastery.com/episodes/21-serialization-with-alba)

> Alba is more feature-rich and pretty fast, too

[Gemfile of dreams by Evil Martians](https://evilmartians.com/chronicles/gemfile-of-dreams-libraries-we-use-to-build-rails-apps)

## Why Alba?

Because it's fast, easy and feature rich!

### Fast

Alba is faster than most of the alternatives. We have a [benchmark](https://github.com/okuramasafumi/alba/tree/main/benchmark).

### Easy

Alba is easy to use because there are only a few methods to remember. It's also easy to understand due to clean and small codebase. Finally it's easy to extend since it provides some methods for override to change default behavior of Alba.

### Feature rich

While Alba's core is simple, it provides additional features when you need them. For example, Alba provides [a way to control circular associations](#circular-associations-control), [root key and association resource name inference](#root-key-and-association-resource-name-inference) and [supports layouts](#layout).

### Other reasons

- Dependency free, no need to install `oj` or `activesupport` while Alba works well with them
- Well tested, the test coverage is 99%
- Well maintained, getting frequent update and new releases (see [version history](https://rubygems.org/gems/alba/versions))

## Comparison with other serializers

Alba aims to provide a well-balanced combination of simplicity, performance, and features. Here's how it compares to other popular Ruby JSON serializers:

| Feature | Alba | [AMS](https://github.com/rails-api/active_model_serializers) | [Blueprinter](https://github.com/procore/blueprinter) | [JSONAPI::Serializer](https://github.com/jsonapi-serializer/jsonapi-serializer) | [JBuilder](https://github.com/rails/jbuilder) |
|---------|------|-----|-------------|---------------------|----------|
| **Dependencies** | [None](https://github.com/okuramasafumi/alba#other-reasons) | ActiveSupport | Minimal | Minimal | Rails |
| **JSON:API Compliance** | Manual | [Planned](https://github.com/rails-api/active_model_serializers#status-of-ams) | Via extension | [Full support](https://github.com/jsonapi-serializer/jsonapi-serializer#json-api-serializer) | Manual |
| **Caching** | [Not built-in](https://github.com/okuramasafumi/alba#caching) | Yes | Via extension | [Supported](https://github.com/jsonapi-serializer/jsonapi-serializer) | [Fragment caching](https://github.com/rails/jbuilder#caching) |
| **Key Transformation** | [Yes](https://github.com/okuramasafumi/alba#key-transformation) | Yes | [Yes](https://github.com/procore/blueprinter) | [Yes](https://goithub.com/jsonapi-serializer/jsonapi-serializer) | [Yes](https://github.com/rails/jbuilder#key-formatting) |
| **Conditional Attributes** | [Yes](https://github.com/okuramasafumi/alba#conditional-attributes) | Yes | [Yes](https://github.com/procore/blueprinter) | [Yes](https://github.com/jsonapi-serializer/jsonapi-serializer) | [Yes](https://github.com/rails/jbuilder) |
| **Type Validation & Coercion** | [Yes](https://github.com/okuramasafumi/alba#types) | No | No | No | No |
| **Custom Type System** | [Yes](https://github.com/okuramasafumi/alba#custom-types) | No | No | No | No |
| **Nested Attributes** | [Yes](https://github.com/okuramasafumi/alba#nested-attribute) | No | No | No | Partial |
| **Circular Reference Control** | [Yes with `within`](https://github.com/okuramasafumi/alba#circular-associations-control) | Limited | No | No | No |
| **Error Handling Strategies** | [Flexible](https://github.com/okuramasafumi/alba#error-handling) | Limited | Limited | Basic | Basic |
| **Nil Handling** | [Yes](https://github.com/okuramasafumi/alba#nil-handling) | No | No | No | No |
| **Layout System** | [Yes](https://github.com/okuramasafumi/alba#layout) | No | No | No | No |
| **Maintenance Status** | Active | [Minimal](https://github.com/rails-api/active_model_serializers#status-of-ams) | Active | Active | Active |

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

Alba supports CRuby 3.0 and higher and latest JRuby and TruffleRuby.

## Documentation

You can find the documentation on [GitHub Pages](https://okuramasafumi.github.io/alba/).

## Features

* Conditional attributes and associations
* Selectable backend
* Key transformation
* Root key and association resource name inference
* Inline definition without explicit classes
* Error handling
* Nil handling
* Circular associations control
* Types for validation and conversion
* Layout
* No runtime dependencies

## Usage

### Configuration

Alba's configuration is fairly simple.

#### Backend configuration

Backend is the actual part serializing an object into JSON. Alba supports these backends.

|name|description|requires_external_gem| encoder|
|--|--|--|--|
|`oj`, `oj_strict`|Using Oj in `strict` mode|Yes(C extension)|`Oj.dump(object, mode: :strict)`|
|`oj_rails`|It's `oj` but in `rails` mode|Yes(C extension)|`Oj.dump(object, mode: :rails)`|
|`oj_default`|It's `oj` but respects mode set by users|Yes(C extension)|`Oj.dump(object)`|
|`active_support`|For Rails compatibility|Yes|`ActiveSupport::JSON.encode(object)`|
|`default`, `json`|Using `json` gem|No|`JSON.generate(object)`|

You can set a backend like this:

```ruby
Alba.backend = :oj
```

This is equivalent as:

```ruby
Alba.encoder = ->(object) { Oj.dump(object, mode: :strict) }
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
if Alba.inflector.nil?
  puts 'inflector not set'
else
  puts "inflector is set to #{Alba.inflector}"
end
```

### Naming

Alba tries to infer resource name from class name like the following.

|Class name|Resource name|
| --- | --- |
| FooResource | Foo |
| FooSerializer | Foo |
| FooElse | FooElse |

Resource name is used as the default name of the root key, so you might want to name it ending with "Resource" or "Serializer"

When you use Alba with Rails, it's recommended to put your resource/serializer classes in corresponding directory such as `app/resources` or `app/serializers`.

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

#### Methods conflict

Consider following code:

```ruby
class Foo
  def bar
    'This is Foo'
  end
end

class FooResource
  include Alba::Resource

  attributes :bar

  def bar
    'This is FooResource'
  end
end

FooResource.new(Foo.new).serialize
```

By default, Alba creates the JSON as `'{"bar":"This is FooResource"}'`. This means Alba calls a method on a Resource class and doesn't call a method on a target object. This rule is applied to methods that are explicitly defined on Resource class, so methods that Resource class inherits from `Object` class such as `format` are ignored.

```ruby
class Foo
  def format
    'This is Foo'
  end
end

class FooResource
  include Alba::Resource

  attributes :bar

  # Here, `format` method is available
end

FooResource.new(Foo.new).serialize
# => '{"bar":"This is Foo"}'
```

If you'd like Alba to call methods on a target object, use `prefer_object_method!` like below.

```ruby
class Foo
  def bar
    'This is Foo'
  end
end

class FooResource
  include Alba::Resource

  prefer_object_method! # <- important

  attributes :bar

  # This is not called
  def bar
    'This is FooResource'
  end
end

FooResource.new(Foo.new).serialize
# => '{"bar":"This is Foo"}'
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

#### Inline associations

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

#### Filtering associations

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
         articles.select { |a| a.id.__send__(filter) && !user.banned }
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

#### Changing a key

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

#### Determining a resource for the association

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

  many :articles, resource: ->(article) { article.with_comment? ? ArticleWithCommentResource : ArticleResource }
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

  one :bar, resource: BarResource, params: {expose_secret: false}
end

Baz = Struct.new(:data, :secret)
Bar = Struct.new(:baz)
Foo = Struct.new(:bar)

foo = Foo.new(Bar.new(Baz.new(1, 'secret')))
FooResource.new(foo, params: {expose_secret: true}).serialize # => '{"foo":{"bar":{"baz":{"data":1,"secret":"secret"}}}}'
FooResourceWithParamsOverride.new(foo, params: {expose_secret: true}).serialize # => '{"foo":{"bar":{"baz":{"data":1}}}}'
```

#### Custom association source

You can specify a custom source for associations using the `source` option with a proc. The `source` proc is executed in the context of the target object and can receive `params` for dynamic behavior. This allows you to retrieve association data from methods other than the association name or access instance variables.

```ruby
class User
  attr_accessor :id, :name, :metadata

  def custom_profile
    {profile: {email: "#{name.downcase}@example.com"}}
  end
end

class UserResource
  include Alba::Resource

  attributes :id, :name

  # Use a custom method as source
  one :profile, source: proc { custom_profile[:profile] }

  # Access instance variables
  one :user_metadata, source: proc { @metadata }
end
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

Although this might be useful sometimes, it's generally recommended to define a class for Resource. Defining a class is often more readable and more maintainable, and inline definitions cannot levarage the benefit of YJIT (it's the slowest with the benchmark YJIT enabled).

#### Alba.hashify

`Alba.hashify` is similar to `Alba.serialize`, but returns a Hash instead of JSON string.

#### Inline definition for multiple root keys

While Alba doesn't directly support multiple root keys, you can simulate it with `Alba.serialize`.

```ruby
# Define foo and bar local variables here

Alba.serialize do
  attribute :key1 do
    FooResource.new(foo).to_h
  end

  attribute :key2 do
    BarResource.new(bar).to_h
  end
end
# => JSON containing "key1" and "key2" as root keys
```

Note that we must use `to_h`, not `serialize`, with resources.

We can also generate a JSON with multiple root keys without making any class by the combination of `Alba.serialize` and `Alba.hashify`.

```ruby
# Define foo and bar local variables here

Alba.serialize do
  attribute :foo do
    Alba.hashify(foo) do
      attributes :id, :name # For example
    end
  end

  attribute :bar do
    Alba.hashify(bar) do
      attributes :id
    end
  end
end
# => JSON containing "foo" and "bar" as root keys
```

#### Inline definition with heterogeneous collection

Alba allows to serialize a heterogeneous collection with `Alba.serialize`.

```ruby
Foo = Data.define(:id, :name)
Bar = Data.define(:id, :address)

class FooResource
  include Alba::Resource

  attributes :id, :name
end

class BarResource
  include Alba::Resource

  attributes :id, :address
end

class CustomFooResource
  include Alba::Resource

  attributes :id
end

foo1 = Foo.new(1, 'foo1')
foo2 = Foo.new(2, 'foo2')
bar1 = Bar.new(1, 'bar1')
bar2 = Bar.new(2, 'bar2')

# This works only when inflector is set
Alba.serialize([foo1, bar1, foo2, bar2], with: :inference)
# => '[{"id":1,"name":"foo1"},{"id":1,"address":"bar1"},{"id":2,"name":"foo2"},{"id":2,"address":"bar2"}]'

Alba.serialize(
  [foo1, bar1, foo2, bar2],
  # `with` option takes a lambda to return resource class
  with: lambda do |obj|
    case obj
    when Foo
      CustomFooResource
    when Bar
      BarResource
    else
      raise # Impossible in this case
    end
  end
)
# => '[{"id":1},{"id":1,"address":"bar1"},{"id":2},{"id":2,"address":"bar2"}]'
# Note `CustomFooResource` is used here

```

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

To filter attributes, you can use `select` instance method. Using `attributes` instance method is deprecated and will be removed in the future.

#### Filtering attributes with `select`

`select` takes two or three parameters, the name of an attribute, the value of an attribute and the attribute object (`Alba::Association`, for example). If it returns false that attribute is rejected.

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

  # This is also possible
  # def select(_key, _value, _attribute)
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

  def camelize(string); end

  def camelize_lower(string); end

  def dasherize(string); end

  def underscore(string); end

  def classify(string); end
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

#### Caution for the second parameter in `if` proc

`if` proc takes two parameters. The first one is the target object, `user` in the example above. The second one is `attribute` representing each attribute `if` option affects. Note that it actually calls attribute methods, so you cannot use it to prevent attribute methods called. This means if the target object is an `ActiveRecord::Base` object and using `association` with `if` option, you might want to skip the second parameter so that the SQL query won't be issued.

Example:

```ruby
class User < ApplicationRecord
  has_many :posts
end

class Post < ApplicationRecord
  belongs_to :user
end

class UserResource
  include Alba::Resource

  # Since `_posts` parameter exists, `user.posts` are loaded
  many :posts, if: proc { |user, _posts| user.admin? }
end

class UserResource2
  include Alba::Resource

  # Since `_posts` parameter doesn't exist, `user.posts` are NOT loaded
  many :posts, if: proc { |user| user.admin? && params[:include_post] }
end
```

### Traits

Traits is an easy way to a group of attributes and apply it to the resource.

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

  attributes :id

  trait :additional do
    attributes :name, :email
  end
end

user = User.new(1, 'Foo', 'foo@example.org')
UserResource.new(user).serialize # => '{"id":1}'
UserResource.new(user, with_traits: :additional).serialize # => '{"id":1,"name":"Foo","email":"foo@example.com"}'
```

This way, we can keep the resource class simple and inject conditions from outside. We can get the same result with the combination of `if` and `params`, but using `traits` DSL can make the resource class readable.

We can specify multiple traits at once with `with_traits: []` keyword argument.

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

  root_key! # This is required to add inferred root key, otherwise it has no root key

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
    raise 'Error!'
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

The block receives five arguments, `error`, `object`, `key`, `attribute` and `resource class` and must return a two-element array. You can also ignore the given key with returning `Alba::REMOVE_KEY`, so that you can get even finer control over errors. Below is an example.

```ruby
class ExampleResource
  include Alba::Resource

  on_error do |error, object, key, attribute, resource_class|
    if resource_class == MyResource
      ['error_fallback', object.error_fallback]
    else
      Alba::REMOVE_KEY
    end
  end
end
```

For more information, consult to [test code](https://github.com/okuramasafumi/alba/blob/main/test/usecases/on_error_test.rb).

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

Note that `on_nil` does NOT work when the given object itself is `nil`. There are a few possible ways to deal with `nil`.

- Use `if` statement and avoid using Alba when the object is `nil`
- Use "Null Object" pattern

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
```

You can change the key for metadata. If you change the key, it also affects the key when you pass `meta` option.

```ruby
# You can change meta key
class UserResourceWithDifferentMetaKey
  include Alba::Resource

  root_key :user, :users

  attributes :id, :name

  meta :my_meta do
    {foo: :bar}
  end
end

UserResourceWithDifferentMetaKey.new([user]).serialize
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}],"my_meta":{"foo":"bar"}}'

UserResourceWithDifferentMetaKey.new([user]).serialize(meta: {extra: 42})
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}],"my_meta":{"foo":"bar","extra":42}}'

class UserResourceChangingMetaKeyOnly
  include Alba::Resource

  root_key :user, :users

  attributes :id, :name

  meta :my_meta
end

UserResourceChangingMetaKeyOnly.new([user]).serialize
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}]}'

UserResourceChangingMetaKeyOnly.new([user]).serialize(meta: {extra: 42})
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}],"my_meta":{"extra":42}}'
```

It's also possible to remove the key for metadata, resulting a flat structure.

```ruby
class UserResourceRemovingMetaKey
  include Alba::Resource

  root_key :user, :users

  attributes :id, :name

  meta nil
end

UserResourceRemovingMetaKey.new([user]).serialize
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}]}'

UserResourceRemovingMetaKey.new([user]).serialize(meta: {extra: 42})
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}],"extra":42}'

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

### Types

You can validate and convert input with types.

```ruby
class User
  attr_reader :id, :name, :age, :bio, :admin, :created_at

  def initialize(id, name, age, bio = '', admin = false)
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

#### Custom types

You can define custom types to abstract data conversion logic. To define custom types, you can use `Alba.register_type` like below.

```ruby
# Typically in initializer
Alba.register_type :iso8601, converter: ->(time) { time.iso8601(3) }, auto_convert: true
```

Then use it as regular types.

```rb
class UserResource
  include Alba::Resource

  attributes :id, created_at: :iso8601
end
```

You now get `created_at` attribute with `iso8601` format!

#### Generating TypeScript types with typelizer gem

We often want TypeScript types corresponding to serializers. That's possible with [typelizer](https://github.com/skryukov/typelizer) gem.

For more information, please read its README.

### Collection serialization into Hash

Sometimes we want to serialize a collection into a Hash, not an Array. It's possible with Alba.

```ruby
class User
  attr_reader :id, :name

  def initialize(id, name)
    @id = id
    @name = name
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

  layout inline: proc {
    {
      header: 'my header',
      body: serializable_hash
    }
  }
end
```

In the example above, we specify a Proc which returns a Hash as an inline layout. In the Proc we can use `serializable_hash` method to access a Hash right before serialization.

You can also use a Proc which returns String, not a Hash, for an inline layout.

```ruby
class FooResource
  include Alba::Resource

  layout inline: proc {
    %({
      "header": "my header",
      "body": #{serialized_json}
    })
  }
end
```

It looks similar to file layout but you must use string interpolation for method calls since it's not an ERB.

Also note that we use percentage notation here to use double quotes. Using single quotes in inline string layout causes the error which might be resolved in other ways.

### Helper

Inheritance works well in most of the cases to share behaviors. One of the exceptions is when you want to shared behaviors with inline association. For example:

```ruby
class ApplicationResource
  include Alba::Resource

  def self.with_id
    attributes(:id)
  end
end

class LibraryResource < ApplicationResource
  with_id
  attributes :created_at

  with_many :library_books do
    with_id # This DOES NOT work!
    attributes :created_at
  end
end
```

This doesn't work. Technically, inside of `has_many` is a separate class which doesn't inherit from the base class (`LibraryResource` in this example).

`helper` solves this problem. It's just a mark for methods that should be shared with inline associations.

```ruby
class ApplicationResource
  include Alba::Resource

  helper do
    def with_id
      attributes(:id)
    end
  end
end
# Now `LibraryResource` works!
```

Within `helper` block, all methods should be defined without `self.`.

### Experimental: modification API

Alba now provides an experimental API to modify existing resource class without adding new classes. Currently only `transform_keys!` is implemented.

Modification API returns a new class with given modifications. It's useful when you want lots of resource classes with small changes. See it in action:

```ruby
class FooResource
  include Alba::Resource

  transform_keys :camel

  attributes :id
end

# Rails app
class FoosController < ApplicationController
  def index
    foos = Foo.where(some: :condition)
    key_transformation_type = params[:key_transformation_type] # Say it's "lower_camel"
    # When params is absent, do not use modification API since it's slower
    resource_class = key_transformation_type ? FooResource.transform_keys!(key_transformation_type) : FooResource
    render json: resource_class.new(foos).serialize # The keys are lower_camel
  end
end
```

The point is that there's no need to define classes for each key transformation type (dash, camel, lower_camel and snake). This gives even more flexibility.

There are some drawbacks with this approach. For example, it creates an internal, anonymous class when it's called, so there is a performance penalty and debugging difficulty. It's recommended to define classes manually when you don't need high flexibility.

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
      attribute(attr) do |object|
        time = object.__send__(attr)
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

#### Using `helper`

When we `extend AlbaExtension` like above, it's not available in inline associations.

```ruby
class BarResource
  include Alba::Resource
  extend AlbaExtension

  # other attributes
  formatted_time_attributes :created_at, :updated_at

  one :something do
    # This DOES NOT work!
    formatted_time_attributes :updated_at
  end
end
```

In this case, we can use [helper](#helper) instead of `extend`.

```ruby
class BarResource
  include Alba::Resource

  helper AlbaExtension # HERE!
  # other attributes
  formatted_time_attributes :created_at, :updated_at

  one :something do
    # This WORKS!
    formatted_time_attributes :updated_at
  end
end
```

You can also pass options to your helpers.

```ruby
module AlbaExtension
  def time_attributes(*attrs, **options)
    attrs.each do |attr|
      attribute(attr, **options) do |object|
        object.__send__(attr).iso8601
      end
    end
  end
end
```

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
  # `...` was added in Ruby 2.7
  def serialize(...)
    puts serializable_hash
    super
  end
end

FooResource.prepend(Logging)
FooResource.new(foo).serialize
# => "{:id=>1}" is printed
```

Here, we override `serialize` method with `prepend`. In overridden method we print the result of `serializable_hash` that gives the basic hash for serialization to `serialize` method. Using `...` allows us to override without knowing method signature of `serialize`.

Don't forget calling `super` in this way.

## Tips and Tricks

### Treating specific classes as non-collection

Sometimes we need to serialize an object that's `Enumerable` but not a collection. By default, Alba treats `Hash`, `Range` and `Struct` as non-collection object, but if we want to add some classes to this list, we can override `Alba.collection?` method like following:

```ruby
Alba.singleton_class.prepend(
  Module.new do
    def collection?(object)
      super && !object.is_a?(SomeClass)
    end
  end
)
```

### Adding indexes to `many` association

Let's say an author has many books. We want returned JSON to include indexes of each book. In this case, we can reduce the number of executed SQL by fetching indexes ahead and push indexes into `param`.

```ruby
Author = Data.define(:id, :books)
Book = Data.define(:id, :name)

book1 = Book.new(1, 'book1')
book2 = Book.new(2, 'book2')
book3 = Book.new(3, 'book3')

author = Author.new(2, [book2, book3, book1])

class AuthorResource
  include Alba::Resource

  attributes :id
  many :books do
    attributes :id, :name
    attribute :index do |bar|
      params[:index][bar.id]
    end
  end
end

AuthorResource.new(
  author,
  params: {
    index: author.books.map.with_index { |book, index| [book.id, index] }
                 .to_h
  }
).serialize
# => {"id":2,"books":[{"id":2,"name":"book2","index":0},{"id":3,"name":"book3","index":1},{"id":1,"name":"book1","index":2}]}
```

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

## Versioning

Alba follows [Semver 2.0.0](https://semver.org/spec/v2.0.0.html).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Alba project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/okuramasafumi/alba/blob/main/CODE_OF_CONDUCT.md).
