---
title: Upgrading from Jbuilder
---

<!-- @format -->

This guide is aimed at helping Jbuilder users transition to Alba, and it consists of three parts:

1. Basic serialization
2. Complex serialization
3. Unsupported features

## Example class

This example will also be replaced by ActiveReord.

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
  attr_reader :email

  def initialize(email)
    @email = email
  end
end

class Article
  attr_accessor :title, :body

  def initialize(title, body)
    @title = title
    @body = body
  end
end
```

## 1. Basic serialization

#### Jbuilder

```rb
# show.json.jbuilder
# With block
@user = User.new(id)
json.user do |user|
  user.id @user.id
  user.created_at @user.created_at
  user.updated_at @user.updated_at
end
# => '{"user":{"id":id, "created_at": created_at, "updated_at": updated_at}'
# or #extract!
json.extract! @user, :id, :created_at, :updated_at
# => '{"id":id, "created_at": created_at, "updated_at": updated_at}'
```

#### Alba

```rb
# With block
user = User.new(id)
Alba.serialize(user, root_key: :user) do
  attributes :id, :created_at, :updated_at
end
# => '{"user":{"id":id, "created_at": created_at, "updated_at": updated_at}'
# or with resourceClass.
# Infer and use by "#{MODEL_NAME}Resource"
class UserResource
  include Alba::Resource
  root_key :user
  attributes :id, :created_at, :updated_at
end
UserResource.new(user).serialize
# => '{"user":{"id":id, "created_at": created_at, "updated_at": updated_at}'
```

## 2. Complex serialization

### Serialize collections

#### Jbuilder

```rb
@users = ids.map { |id| User.new(id) }
# index.json.jbuilder
json.array! @users, :id, :created_at, :updated_at
# => '[{"id":id, "created_at": created_at, "updated_at": updated_at}, {"id":id, "created_at": created_at, "updated_at": updated_at}, {"id":id, "created_at": created_at, "updated_at": updated_at}]'
```

#### Alba

```rb
class UserResource
  include Alba::Resource
  root_key :user
  attributes :id, :created_at, :updated_at
end
users = ids.map { |id| User.new(id) }
UserResource.new(users).serialize
# => '[{"id":id, "created_at": created_at, "updated_at": updated_at}, {"id":id, "created_at": created_at, "updated_at": updated_at}, {"id":id, "created_at": created_at, "updated_at": updated_at}]'

```

### Nested serialization

#### Jbuilder

```rb
# show.json.jbuilder
@user = User.new(id)
@user.profile = Profile.new(email)
@user.articles = [Article.new(title, body)]
json.user do |user|
  user.id @user.id
  user.created_at @user.created_at
  user.updated_at @user.updated_at
  json.profile do
    json.email @user.profile.email
  end
  json.articles do
    json.array! @user.articles, :title, :body
  end
end
# => '{"user":{"id":id, "created_at": created_at, "updated_at": updated_at, "profile": {"email": email}, articles: [{"title": title, "body": body}]}'
# or #merge!
profile_hash = { profile: { email: @user.profile.email } }
articles_hash = { articles: @user.articles.map { |article| { title: article.title, body: article.body } } }
json.user do |user|
  user.id @user.id
  user.created_at @user.created_at
  user.updated_at @user.updated_at
  json.merge! profile_hash
  json.merge! articles_hash
end
# => '{"user":{"id":id, "created_at": created_at, "updated_at": updated_at, "profile": {"email": email}, articles: [{"title": title, "body": body}]}'
# or #partial!
# profiles/_profile.json.jbuilder
json.profile do
  json.email @profile.email
end
# articles/_article.json.jbuilder
json.extract! article, :title, :body
# user/show.json.jbuilder
json.user do |user|
  user.id @user.id
  user.created_at @user.created_at
  user.updated_at @user.updated_at
  json.partial! @user.profile, as: :profile
  json.articles @user.articles do |article|
    json.partial! article, partial: 'articles/article'
  end
end
```

#### Alba

```rb
# With ResourceClass by each resources
class ProfileResource
  include Alba::Resource
  root_key :profile
  attributes :email
end
class ArticleResource
  include Alba::Resource
  root_key :article
  attributes :title, :body
end
class UserResource
  include Alba::Resource
  root_key :user
  attributes :id, :created_at, :updated_at
  one :profile, resource: ProfileResource
  many :articles, resource: ArticleResource
end
user = User.new(id)
user.profile = Profile.new(email)
user.articles = [Article.new(title, body)]
UserResource.new(user).serialize
# => '{"user":{"id":id, "created_at": created_at, "updated_at": updated_at, "profile": {"email": email}, articles: [{"title": title, "body": body}]}'

# or #attribute
class UserResource
  include Alba::Resource
  root_key :user
  attributes :id, :created_at, :updated_at

  attribute :profile do
    {
      email: object.profile.email # Can access to received resource by #object method
    }
  end

  attribute :articles do
    object.articles.map do |article|
      {
        title: article.title,
        body: article.body,
      }
    end
  end
end
user = User.new(id)
user.profile = Profile.new(email)
UserResource.new(user).serialize
# => '{"user":{"id":id, "created_at": created_at, "updated_at": updated_at, "profile": {"email": email}, articles: [{"title": title, "body": body}]}'
```

## 3. Unsupported features

- Jbuilder#ignore_nil!
- Jbuilder#cache!
- Jbuilder.key_format! and Jbuilder.deep_format_keys!
