# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- [Breaking change] `serializable_hash` now respects the `root_key` option

`serializable_hash` now has the same options and defaults as the `serialize` method. This means it now respects the `root_key` configuration on your resource, which may be a breaking change for applications using `root_key` in conjunction with `serializable_hash`.

Note that `serializable_hash` is aliased as `to_h`, and `serialize` is aliased as `to_json`.

To illustrate and provide a workaround if you wish to maintain the old behavior:

```ruby
class User
  attr_accessor :id

  def initialize(id)
    @id = id
  end
end

class UserResource
  include Alba::Resource

  root_key :user

  attributes :id
end

user = User.new(1)
```

```ruby
# Alba v1:
UserResource.new(user).serialize # => "{"user":{"id":1}}"
UserResource.new(user).serializable_hash # => {:id=>1}

# Alba v2:
UserResource.new(user).serialize # => "{"user":{"id":1}}"
UserResource.new(user).serializable_hash # => {"user"=>{:id=>1}}
```

Note that v2 is now more consistent between the JSON and Ruby Hash implementations, but if you'd like to maintain the v1 behavior, you have two options.

Option 1 is to pass `root_key: false` anywhere you want the old behavior:

```ruby
UserResource.new(user).serializable_hash(root_key: false) # => {:id=>1}
UserResource.new(user).to_h(root_key: false) # => {:id=>1}
```

Option 2 is to define a `default_root_key` on your resource which returns `false`:

```ruby
class UserResource
  include Alba::Resource

  root_key :user

  attributes :id

  def default_root_key
    false
  end
end

UserResource.new(user).serialize # => # => "{"user":{"id":1}}"
UserResource.new(user).serializable_hash # => {:id=>1}
```

If you'd to maintain the old behavior throughout your application, consider using class inheritance with a base `ApplicationResource`, for example:

```ruby
class ApplicationResource
  include Alba::Resource

  def default_root_key
    false
  end
end

class UserResource < ApplicationResource
  include Alba::Resource

  root_key :user

  attributes :id
end

class OtherResource < ApplicationResource
  # This resource will also maintain the old behavior
end

UserResource.new(user).serialize # => # => "{"user":{"id":1}}"
UserResource.new(user).serializable_hash # => {:id=>1}
```

## [1.6.0] 2022-03-16

- [Feat] Support instance method as an attribute
- [Fix] Explicitly raise error when inference is disabled
- [Improve] `enable_inference!` now takes inflector as argument
- [Improve] `transform_keys` now accepts `:snake` and `:none`
- [Deprecate] `to_hash` is special method and should not be used
- [Deprecate] `ignoring` in favor of `attributes` overriding
- [Deprecate] `Alba.on_nil`, `Alba.on_error` and `Alba.enable_root_key_transformation!`

## [1.5.0] 2021-11-28

- [Feat] Add nil handler
- [Feat] Implement layout feature
- [Improve] if option now works with Symbol
- [Improve] Add an alias for serialize
- [Improve] Deprecation warning now printed with caller

## [1.4.0] 2021-06-30

- [Feat] Add a config method to set encoder directly
- [Feat] Implement `meta` method and option for metadata
- [Feat] Add `root_key` option to `Resource#serialize`
- [Feat] Enable setting key for collection with `root_key`
- [Feat] Add `Resource.root_key` and `Resource.root_key!`
- [Feat] `Alba.serialize` now infers resource class
- [Deprecated] `Resource.key` and `Resource.key!` are deprecated

## [1.3.0] 2021-05-31

- [Perf] Improve performance for `many` [641d8f9]
  - https://github.com/okuramasafumi/alba/pull/125
- [Feat] Add custom inflector feature (#126) [ad73291]
  - https://github.com/okuramasafumi/alba/pull/126
  - Thank you @wuarmin !
- [Feat] Support params in if condition [6e9915e]
  - https://github.com/okuramasafumi/alba/pull/128
- [Fix] fundamentally broken "circular association control" [fbbc9a1]
  - https://github.com/okuramasafumi/alba/pull/130

## [1.2.0] 2021-05-09

- [Fix] multiple word key inference [6c18e73]
  - https://github.com/okuramasafumi/alba/pull/120
  - Thank you @alfonsojimenez !
- [Feat] Add `Alba.enable_root_key_transformation!` [f172839]
  - https://github.com/okuramasafumi/alba/pull/121
- [Feat] Implement type validation and auto conversion [cbe00c7]
  - https://github.com/okuramasafumi/alba/pull/122

## [1.1.0] - 2021-04-23

- [Feat] Implement circular associations control [71e1543]
- [Feat] Support :oj_rails backend [76e519e]

## [1.0.1] - 2021-04-15

- [Fix] Don't cache resource class for `Alba.serialize` [9ed5253]
- [Improve] Warn when `ActiveSupport` or `Oj` are absent [d3ab3eb]
- [Fix] Delete unreachable `to_hash` method on Association [1ba1f90]
- [Fix] Stringify key before transforming [b4eb79e]
- [Misc] Support Ruby 2.5.0 and above, not 2.5.7 and above [43f1d17]
- [Fix] Remove accidentally added `p` debug [5d0324b]

## [1.0.0] - 2021-04-07

This is the first major release of Alba and it includes so many features. To see all the features you can have a look at [README](https://github.com/okuramasafumi/alba/blob/master/README.md#features).
