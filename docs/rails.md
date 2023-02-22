---
title: Alba for Rails
author: OKURA Masafumi
---

# Alba for Rails

While Alba is NOT designed for Rails specifically, you can definitely use Alba with Rails. This document describes in detail how to use Alba with Rails to be more productive.

## Initializer

You might want to add some configurations to initializer file such as `alba.rb` with something like below:

```ruby
# alba.rb
Alba.backend = :active_support
Alba.inflector = :active_support
```

You can also use `:oj_rails` for backend if you prefer using Oj.

Alba 2.2 introduced new Rails integration so that you don't have to add initializer file for setting inflector. You still need to add initializer file if you want to set backend or configure inflector with something different from `active_support`.

## Rendering JSON

You can render JSON with Rails in two ways. One way is to pass JSON String.

```ruby
render json: FooResource.new(foo).serialize
```

But you can also render JSON passing `Alba::Resource` object. Rails automatically calls `to_json` on a resource.

```ruby
render json: FooResource.new(foo)
```

Note that almost all options given to this `render` are ignored. The only exceptions are `layout`, `prefixes`, `template` and `status`.

```ruby
# This `only` option is ignored
render json: FooResource.new(foo), only: [:id]

# This is OK
render json: FooResource.new(foo), status: 200
```
