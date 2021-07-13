---
title: Upgrading from ActiveModelSerializers
---

<!-- @format -->

This guide is aimed at helping ActiveModelSerializers users transition to Alba, and it consists of three parts:

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

### #serializable_hash

- or #as_json, #to_json

#### When ActiveModelSerializer

```rb
# Infer and use by "#{MODEL_NAME}Serializer" in app/serialziers/user_serialzier.rb
class UserSerialzier < ActiveModel::Serializer
  type :user
  attributes :id, :created_at, :updated_at
end

# serialze
ActiveModelSerializers::SerializableResource.new(
  user, # User instance
).serializable_hash
=> {
  user: {
    id: id,
    created_at: created_at,
    updated_at: updated_at
  }
}

```

#### When Alba

```rb
# Infer and use by "#{MODEL_NAME}Resource"
# In app/resources/user_resource.rb
class UserResource
  include Alba::Resource
  attributes :id, :created_at, :updated_at
end

# serialze
UserResource.new(user).serializable_hash
=> {
  id: id,
  created_at: created_at,
  updated_at: updated_at,
}

# If want `user key`
class UserResource
  include Alba::Resource
  root_key :user # Call root_key method like ActiveModel::Serializer#type
  attributes :id, :created_at, :updated_at
end

# serialze
JSON.parse UserResource.new(user).serialize # ！！！！serializable_hash does not support root key！！！ Must use JSON.parse and serialize
=> {
  "user"=>{
    "id"=>id,
    "created_at"=>created_at,
    "updated_at"=>updated_at
  }
}
# If want symbolize keys
JSON.parse(UserResource.new(user).serialize).deep_symbolize_keys
=> {
  user: {
    id: id,
    created_at: created_at,
    updated_at: updated_at
  }
}
```

## 2. Complexity serialization

### Serialize collections

#### When ActiveModelSerializer

```rb
class UserSerialzier < ActiveModel::Serializer
  type :user
  attributes :id, :created_at, :updated_at
end

ActiveModelSerializers::SerializableResource.new(
  users,
  adapter: :attributes # Comment out this line if you want users key
  # Want to specified key to call with root: args
).serializable_hash
=> [{:id=>1, :created_at=>created_at, :updated_at=>updated_at},
   {:id=>2, :created_at=>created_at, :updated_at=>updated_at},
   {:id=>3, :created_at=>created_at, :updated_at=>updated_at}]
```

#### When Alba

```rb
class UserResource
  include Alba::Resource
  attributes :id, :created_at, :updated_at
end
UserResource.new(users).serializable_hash
=>[{:id=>1, :created_at=>created_at, :updated_at=>updated_at},
   {:id=>2, :created_at=>created_at, :updated_at=>updated_at},
   {:id=>3, :created_at=>created_at, :updated_at=>updated_at}]
# or
JSON.parse UserResource.new(users).serialize(root_key: :users)
=> {"users"=>
  [{"id"=>1, "created_at"=>created_at, "updated_at"=>updated_at},
   {"id"=>2, "created_at"=>created_at, "updated_at"=>updated_at},
   {"id"=>3, "created_at"=>created_at, "updated_at"=>updated_at}]}
```

### Nested serialization

#### When ActiveModelSerializer

```rb
class ProfileSerialzier < ActiveModel::Serializer
  type :profile
  attributes :id, :created_at, :updated_at
end

class ArticleSerialzier < ActiveModel::Serializer
  type :article
  attributes :id, :created_at, :updated_at
end

class UserSerialzier < ActiveModel::Serializer
  type :user
  attributes :id, :created_at, :updated_at
  has_one :profile, serializer: ProfileSerialzier # For has_one relation
  has_many :articles, serializer: ArticleSerialzier # For has_many relation
end

ActiveModelSerializers::SerializableResource.new(
  user
).serializable_hash
=> {
  :user=> {
    :id=>1,
    :created_at=>created_at,
    :updated_at=>updated_at,
    :profile=> {
      :id=>1,
      :created_at=>created_at,
      :updated_at=>updated_at
    },
    :articles => [
      {
        :id=>1,
        :created_at=>created_at,
        :updated_at=>updated_at
      }
    ]
  }
}
```

#### When Alba

```rb
class ProfileResource
  include Alba::Resource
  root_key :profile
  attributes :id, :created_at, :updated_at
end

class ArticleResource
  include Alba::Resource
  root_key :article
  attributes :id, :created_at, :updated_at
end

class UserResource
  include Alba::Resource
  root_key :user
  attributes :id, :created_at, :updated_at
  one :profile, resource: ProfileResource # For has_one relation
  many :articles, resource: ArticleResource # For has_many relation
end

UserResource.new(user).serializable_hash
=> {
  :id=>1,
  :created_at=>created_at,
  :updated_at=>updated_at,
  :profile=> {
    :id=>1,
    :created_at=>created_at,
    :updated_at=>updated_at
  },
  :articles => [
    {
      :id=>1,
      :created_at=>created_at,
      :updated_at=>updated_at
    }
  ]
}

```

### Serialize with custom serializer

#### When ActiveModelSerializer

```rb
class CustomUserSerialzier < ActiveModel::Serializer
  type :user
  attribute :name do
    object.profile.name
  end
end

# serialze
ActiveModelSerializers::SerializableResource.new(
  user,
  serializer: ::CustomUserSerialzier # Call with serializer arg
).serializable_hash
=> {
  user: {
    name: name
  }
}
```

#### When Alba

```rb
class CustomUserResource
  include Alba::Resource
  root_key :user
  attribute :name do
    object.profile.name
  end
end

# serialze
CustomUserResource.new(user).serializable_hash
=> {
  name: name
}
```

### Passing arbitrary options to a serializer

#### When ActiveModelSerializer

```rb
class UserSerializer < ApplicationSerializer
  type :user
  attributes :id, :created_at, :updated_at
  attribute :custom_params do
    pp instance_options
    # => given_params: { a: :b }
    instance_options # Access by instance_options method
  end
end

# serialze
ActiveModelSerializers::SerializableResource.new(
  user,
  given_params: { a: :b } # Give with your favorite keyword argument
).serializable_hash
=> {
  :id=>1,
  :created_at=>created_at,
  :updated_at=>updated_at,
  :custom_params=>{
    :given_params=>{
      :a=>:b
    }
  }
}
```

#### When Alba

```rb
class UserResource
  include Alba::Resource
  root_key :user
  attributes :id, :created_at, :updated_at
  attribute :custom_params do
    pp params
    # => { :a=>:b }
    params
  end
end

# serialze
UserResource.new(
  user,
  params: { a: :b } # Give with :params keyword argument
).serializable_hash
=> {
  :id=>1,
  :created_at=>created_at,
  :updated_at=>updated_at,
  :custom_params=>{
    :a=>:b
  }
}
```

## 3. Unsupported features

- [RelationshipLinks](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/howto/add_relationship_links.md)
- [PaginationLinks](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/howto/add_pagination_links.md)
- [Logging](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/general/logging.md)
- [Caching](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/general/caching.md)
- [Rendering](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/general/rendering.md)
