[![Gem Version](https://badge.fury.io/rb/alba.svg)](https://badge.fury.io/rb/alba)
[![CI](https://github.com/okuramasafumi/alba/actions/workflows/main.yml/badge.svg)](https://github.com/okuramasafumi/alba/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/okuramasafumi/alba/branch/master/graph/badge.svg?token=3D3HEZ5OXT)](https://codecov.io/gh/okuramasafumi/alba)
[![Maintainability](https://api.codeclimate.com/v1/badges/fdab4cc0de0b9addcfe8/maintainability)](https://codeclimate.com/github/okuramasafumi/alba/maintainability)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/okuramasafumi/alba)
![GitHub](https://img.shields.io/github/license/okuramasafumi/alba)

# Alba

Alba is the fastest JSON serializer for Ruby, JRuby, and TruffleRuby.

## Discussions

Alba uses [GitHub Discussions](https://github.com/okuramasafumi/alba/discussions) to openly discuss the project.

If you've already used Alba, please consider posting your thoughts and feelings on [Feedback](https://github.com/okuramasafumi/alba/discussions/categories/feedback). The fact that you enjoy using Alba gives me energy to keep developing Alba!

If you have feature requests or interesting ideas, join us with [Ideas](https://github.com/okuramasafumi/alba/discussions/categories/ideas). Let's make Alba even better, together!

## Why Alba?

Because it's fast, flexible and well-maintained!

### Fast

Alba is faster than most of the alternatives. We have a [benchmark](https://github.com/okuramasafumi/alba/tree/master/benchmark).

### Flexible

Alba provides a small set of DSL to define your serialization logic. It also provides methods you can override to alter and filter serialized hash so that you have full control over the result.

### Maintained

Alba is well-maintained and adds features quickly. [Coverage Status](https://coveralls.io/github/okuramasafumi/alba?branch=master) and [CodeClimate Maintainability](https://codeclimate.com/github/okuramasafumi/alba/maintainability) show the code base is quite healthy.

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

Alba supports CRuby 2.5 and higher and latest JRuby and TruffleRuby.

## Documentation

You can find the documentation on [RubyDoc](https://rubydoc.info/github/okuramasafumi/alba).

## Features

* Conditional attributes and associations
* Selectable backend
* Key transformation
* Root key inference
* Error handling
* Nil handling
* Resource name inflection based on association name
* Circular associations control
* [Experimental] Types for validation and conversion
* Layout
* No runtime dependencies

## Usage

### Configuration

Alba's configuration is fairly simple.

#### Backend configuration

Backend is the actual part serializing an object into JSON. Alba supports these backends.

* Oj, the fastest. Gem installation required.
* active_support, mostly for Rails. Gem installation required.
* default or json, with no external dependencies.

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

You can enable inference feature using `enable_inference!` method.

```ruby
Alba.enable_inference!
```

You must install `ActiveSupport` to enable inference.

#### Error handling configuration

You can configure error handling with `on_error` method.

```ruby
Alba.on_error :ignore
```

For the details, see [Error handling section](#error-handling)

### Simple serialization with root key

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
# => "{\"user\":{\"id\":1,\"name\":\"Masafumi OKURA\",\"name_with_email\":\"Masafumi OKURA: masafumi@example.com\"}}"
```

### Serialization with associations

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

You can "filter" association using second proc argument. This proc takes association object and `params`.

This feature is useful when you want to modify association, such as adding `includes` or `order` to ActiveRecord relations.

```ruby
class User
  attr_reader :id
  attr_accessor :articles

  def initialize(id)
    @id = id
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
    proc { |articles, params|
      filter = params[:filter] || :odd?
      articles.select {|a| a.id.send(filter) }
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

### Inheritance and Ignorance

You can `exclude` or `ignore` certain attributes using `ignoring`.

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
  ignoring :id, :body
end

RestrictedFooResource.new(foo).serialize
# => '{"name":"my foo"}'
```

### Key transformation

If you want to use `transform_keys` DSL and you already have `active_support` installed, key transformation will work out of the box, using `ActiveSupport::Inflector`. If `active_support` is not around, you have 2 possibilities:
* install it
* use a [custom inflector](#custom-inflector)

With `transform_keys` DSL, you can transform attribute keys.

```ruby
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

You can also transform root key when:

* `Alba.enable_inference!` is called
* `root_key!` is called in Resource class
* `root` option of `transform_keys` is set to true or `Alba.enable_root_key_transformation!` is called.

```ruby
Alba.enable_inference!

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

This behavior to transform root key will become default at version 2.

Supported transformation types are :camel, :lower_camel and :dash.

#### Custom inflector

A custom inflector can be plugged in as follows...
```ruby
Alba.inflector = MyCustomInflector
```
...and has to implement following interface (the parameter `key` is of type `String`):
```ruby
module InflectorInterface
  def camelize(key)
    raise "Not implemented"
  end

  def camelize_lower(key)
    raise "Not implemented"
  end

  def dasherize(key)
    raise "Not implemented"
  end
end

```
For example you could use `Dry::Inflector`, which implements exactly the above interface. If you are developing a `Hanami`-Application `Dry::Inflector` is around. In this case the following would be sufficient:
```ruby
Alba.inflector = Dry::Inflector.new
```

### Filtering attributes

You can filter attributes by overriding `Alba::Resource#converter` method, but it's a bit tricky.

```ruby
class User
  attr_accessor :id, :name, :email, :created_at, :updated_at

  def initialize(id, name, email)
    @id = id
    @name = name
    @email = email
  end
end

class UserResource
  include Alba::Resource

  attributes :id, :name, :email

  private

  # Here using `Proc#>>` method to compose a proc from `super`
  def converter
    super >> proc { |hash| hash.compact }
  end
end

user = User.new(1, nil, nil)
UserResource.new(user).serialize # => '{"id":1}'
```

The key part is the use of `Proc#>>` since `Alba::Resource#converter` returns a `Proc` which contains the basic logic and it's impossible to change its behavior by just overriding the method.

It's not recommended to swap the whole conversion logic. It's recommended to always call `super` when you override `converter`.

### Conditional attributes

Filtering attributes with overriding `convert` works well for simple cases. However, It's cumbersome when we want to filter various attributes based on different conditions for keys.

In these cases, conditional attributes works well. We can pass `if` option to `attributes`, `attribute`, `one` and `many`. Below is an example for the same effect as [filtering attributes section](#filtering-attributes).

```ruby
class User
  attr_accessor :id, :name, :email, :created_at, :updated_at

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

### Inference

After `Alba.enable_inference!` called, Alba tries to infer root key and association resource name.

```ruby
Alba.enable_inference!

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

  key!

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

Note that to enable this feature you must install `ActiveSupport` gem.

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
# Global error handling
Alba.on_error do |error, object, key, attribute, resource_class|
  if resource_class == MyResource
    ['error_fallback', object.error_fallback]
  else
    [key, error.message]
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
    if key == age
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

You can also set global nil handler.

```ruby
Alba.on_nil { 'default name' }

class Foo
  attr_reader :name
  def initialize(name)
    @name = name
  end
end

class FooResource
  include Alba::Resource

  key :foo

  attributes :name
end

FooResource.new(Foo.new).serialize
# => '{"foo":{"name":"default name"}}'

class FooResource2
  include Alba::Resource

  key :foo

  on_nil { '' } # This is applied instead of global handler

  attributes :name
end

FooResource2.new(Foo.new).serialize
# => '{"foo":{"name":""}}'
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

UserResource.new([user]).serialize(meta: {foo: :bar})
# => '{"users":[{"id":1,"name":"Masafumi OKURA"}],"meta":{"foo":"bar"}}'
```

You can use `object` method to access the underlying object and `params` to access the params in `meta` block.

Note that setting root key is required when setting a metadata.

### Circular associations control

**Note that this feature works correctly since version 1.3. In previous versions it doesn't work as expected.**

You can control circular associations with `within` option. `within` option is a nested Hash such as `{book: {authors: books}}`. In this example, Alba serializes a book's authors' books. This means you can reference `BookResource` from `AuthorResource` and vice versa. This is really powerful when you have a complex data structure and serialize certain parts of it.

For more details, please refer to [test code](https://github.com/okuramasafumi/alba/blob/master/test/usecases/circular_association_test.rb)

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

## Rails

When you use Alba in Rails, you can create an initializer file with the line below for compatibility with Rails JSON encoder.

```ruby
Alba.backend = :active_support
# or
Alba.backend = :oj_rails
```

## Why named "Alba"?

The name "Alba" comes from "albatross", a kind of birds. In Japanese, this bird is called "Aho-dori", which means "stupid bird". I find it funny because in fact albatrosses fly really fast. I hope Alba looks stupid but in fact it does its job quick.

## Pioneers

There are great pioneers in Ruby's ecosystem which does basically the same thing as Alba does. To name a few:

* [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers) a.k.a AMS, the most famous implementation of JSON serializer for Ruby
* [Blueprinter](https://github.com/procore/blueprinter) shares some concepts with Alba

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/okuramasafumi/alba. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/okuramasafumi/alba/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Alba project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/okuramasafumi/alba/blob/master/CODE_OF_CONDUCT.md).
