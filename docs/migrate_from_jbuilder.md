---
title: Upgrading from Jbuilder
---

<!-- @format -->

This guide is aimed at helping Jbuilder users transition to Alba, and it consists of three parts:

1. Basically serialization
2. Complexity serialization
3. Unsupported features

## Example class

```rb
class User
  attr_reader :id, :created_at, :updated_at
  attr_accessor :profile, :articles

  def initialize(id)
    @id = id
    @created_at = Time.now
    @updated_at = Time.now
    @articles = []
  end
end

class Profile
  attr_reader :user_id, :email

  def initialize(user_id, email)
    @user_id = user_id
    @email = email
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
```

## 1. Basically serialization

```rb
# When Jbuilder
# index.json.jbuilder
json.user do |user|
  user.id @user.id
  user.created_at @user.created_at
  user.updated_at @user.updated_at
end
=> '{"user":{"id":id,created_at: created_at, updated_at: updated_at}'
# When Alba
Alba.serialize(user, key: :user) do
  attributes :id, created_atupdated_at
end
=> '{"user":{"id":id,created_at: created_at, updated_at: updated_at}'
```

## 2. Complexity serialization

## 3. Unsupported features
