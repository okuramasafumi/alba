[![Gem Version](https://badge.fury.io/rb/alba.svg)](https://badge.fury.io/rb/alba)
[![CI](https://github.com/okuramasafumi/alba/actions/workflows/main.yml/badge.svg)](https://github.com/okuramasafumi/alba/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/okuramasafumi/alba/branch/master/graph/badge.svg?token=3D3HEZ5OXT)](https://codecov.io/gh/okuramasafumi/alba)
[![Maintainability](https://api.codeclimate.com/v1/badges/fdab4cc0de0b9addcfe8/maintainability)](https://codeclimate.com/github/okuramasafumi/alba/maintainability)
[![Inline docs](http://inch-ci.org/github/okuramasafumi/alba.svg?branch=main)](http://inch-ci.org/github/okuramasafumi/alba)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/okuramasafumi/alba)
![GitHub](https://img.shields.io/github/license/okuramasafumi/alba)

# Alba

`Alba` is the fastest JSON serializer for Ruby, JRuby an TruffleRuby.

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

Alba supports CRuby 2.5.7 and higher and latest JRuby and TruffleRuby.

## Documentation

You can find the documentation on [RubyDoc](https://rubydoc.info/github/okuramasafumi/alba).

## Features

* Resource-based serialization
* Arbitrary attribute definition
* One and many association with the ability to define them inline
* Adding condition and filter to association
* Parameters can be injected and used in attributes and associations
* Conditional attributes and associations
* Selectable backend
* Key transformation
* Root key inference
* Error handling
* Resource name inflection based on association name
* No runtime dependencies

## Anti features

* Sorting keys
* Class level support of parameters
* Supporting all existing JSON encoder/decoder
* Cache
* [JSON:API](https://jsonapi.org) support
* And many others

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

### Simple serialization with key

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

  key :user

  attributes :id, :name

  attribute :name_with_email do |resource|
    "#{resource.name}: #{resource.email}"
  end
end

user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
UserResource.new(user).serialize
# => "{\"id\":1,\"name\":\"Masafumi OKURA\",\"name_with_email\":\"Masafumi OKURA: masafumi@example.com\"}"
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

### Inline definition with `Alba.serialize`

`Alba.serialize` method is a shortcut to define everything inline.

```ruby
Alba.serialize(user, key: :foo) do
  attributes :id
  many :articles do
    attributes :title, :body
  end
end
# => '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}'
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

class RestrictedFooResouce < GenericFooResource
  ignoring :id, :body
end

RestrictedFooResouce.new(foo).serialize
# => '{"name":"my foo"}'
end
```

### Attribute key transformation

** Note: You need to install `active_support` gem to use `transform_keys` DSL.

With `active_support` installed, you can transform attribute keys.

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

Supported transformation types are :camel, :lower_camel and :dash.

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

### Caching

Currently, Alba doesn't support caching, primarily due to the behavior of `ActiveRecord::Relation`'s cache. See [the issue](https://github.com/rails/rails/issues/41784).

## Comparison

Alba is faster than alternatives.
For a performance benchmark, see https://gist.github.com/okuramasafumi/4e375525bd3a28e4ca812d2a3b3e5829.

## Rails

When you use Alba in Rails, you can create an initializer file with the line below for compatibility with Rails JSON encoder.

```ruby
Alba.backend = :active_support
```

## Why named "Alba"?

The name "Alba" comes from "albatross", a kind of birds. In Japanese, this bird is called "Aho-dori", which means "stupid bird". I find it funny because in fact albatrosses fly really fast. I hope Alba looks stupid but in fact it does its job quick.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/okuramasafumi/alba. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/okuramasafumi/alba/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Alba project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/okuramasafumi/alba/blob/master/CODE_OF_CONDUCT.md).
