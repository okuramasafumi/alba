[![Gem Version](https://badge.fury.io/rb/alba.svg)](https://badge.fury.io/rb/alba)
[![Build Status](https://travis-ci.com/okuramasafumi/alba.svg?branch=master)](https://travis-ci.com/okuramasafumi/alba)
[![Coverage Status](https://coveralls.io/repos/github/okuramasafumi/alba/badge.svg?branch=master)](https://coveralls.io/github/okuramasafumi/alba?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/fdab4cc0de0b9addcfe8/maintainability)](https://codeclimate.com/github/okuramasafumi/alba/maintainability)

# Alba

`Alba` is the fastest JSON serializer for Ruby.

# Why yet another JSON serializer?

We know that there are several other JSON serializers for Ruby around, but none of them made us satisfied.

Alba has some advantages over other JSON serializers which we've wanted to have.

## Easy to understand

DSL is great. It makes the coding experience natural and intuitive. However, remembering lots of DSL requires us a lot of effort. Unfortunately, most of the existing libraries have implemented their features via DSL and it's not easy to understand how they behave entirely. Alba's core DSL are only four (`attributes`, `attribute`, `one` and `many`) so it's easy to understand how to use.

Alba is also understandable internally. The codebase is much smaller than the alternatives. In fact, it's less than 300 lines of code. Look at the code on [GitHub](https://github.com/okuramasafumi/alba/tree/master/lib) and you'll be surprised how simple it is!

## Performance

Alba is faster than most of the alternatives. We have a [benchmark](https://gist.github.com/okuramasafumi/4e375525bd3a28e4ca812d2a3b3e5829).

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

Alba supports CRuby 2.5.7 and higher, latest JRuby and latest TruffleRuby.

## Usage

### Configuration

Alba's configuration is fairly simple.

#### Backend

Backend is the actual part serializing an object into JSON. Alba supports these backends.

* Oj, the fastest. Gem installation required.
* active_support, mostly for Rails. Gem installation required.
* default or json, with no external dependencies.

You can set a backend like this:

```ruby
Alba.backend = :oj
```

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

  attributes :id, :name

  attribute :name_with_email do |resource|
    "#{resource.name}: #{resource.email}"
  end
end

class SerializerWithKey
  include Alba::Serializer

  set key: :user
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

class UserResource1
  include Alba::Resource

  attributes :id

  many :articles, resource: ArticleResource
end

user = User.new(1)
article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
user.articles << article1
article2 = Article.new(2, 'Super nice', 'Really nice!')
user.articles << article2

UserResource1.new(user).serialize
# => '{"id":1,"articles":[{"title":"Hello World!"},{"title":"Super nice"}]}'
```

### Inline definition with `Alba.serialize`

`Alba.serialize` method is a shortcut to define everything inline.

```ruby
Alba.serialize(user, with: proc { set key: :foo }) do
  attributes :id
  many :articles do
    attributes :title, :body
  end
end
# => '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}'
```

Although this might be useful sometimes, it's generally recommended to define a class for both Resource and Serializer.

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

## Alba internals

Alba has three component, `Serializer`, `Resource` and `Value` (`Value` is conceptual and not implemented directly).

`Serializer` is a component responsible for rendering JSON output with `Resource`. `Serializer` can add more data to `Resource` such as `metadata`. Users can define one single `Serializer` and reuse it for all `Resource`s. The main interface is `#serialize`.

`Resource` is a component responsible for defining how an object (or a collection of objects) is converted into JSON. The difference between `Serializer` and `Resource` is that while `Serializer` can add arbitrary data into JSON, `Resource` can get data only from the object under it. The main interface is `#serializable_hash`.

`One` and `Many` are the special object fetching other resources and converting them into Hash.

The main `Alba` module holds config values and one convenience method, `.serialize`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/okuramasafumi/alba. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/okuramasafumi/alba/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Alba project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/okuramasafumi/alba/blob/master/CODE_OF_CONDUCT.md).
