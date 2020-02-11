# Alba

`Alba` is a fast and flexible JSON serializer.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alba'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install alba

## Usage

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/okuramasafumi/alba. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/okuramasafumi/alba/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Alba project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/okuramasafumi/alba/blob/master/CODE_OF_CONDUCT.md).
