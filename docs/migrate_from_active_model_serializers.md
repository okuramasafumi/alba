---
title: Upgrading from ActiveModelSerializers
---

<!-- @format -->

This guide is aimed at helping ActiveModelSerializers users transition to Alba, and it consists of three parts:

1. Basic serialization
2. Complex serialization
3. Unsupported features

## Example class

Example clsss is inherited `ActiveRecord::Base`, because [serializing PORO with AMS is pretty hard](https://github.com/rails-api/active_model_serializers/blob/0-10-stable/docs/howto/serialize_poro.md).

```rb
class User < ActiveRecord::Base
  # columns: id, created_at, updated_at
  has_one :profile
  has_many :articles
end

class Profile < ActiveRecord::Base
  # columns: id, user_id, email, created_at, updated_at
  belongs_to :user
end

class Article < ActiveRecord::Base
  # columns: id, user_id, title, body, created_at, updated_at
  belongs_to :user
end
```

## 1. Basic serialization

### #serializable_hash

- or #as_json, #to_json

#### ActiveModelSerializer

```rb
# Infer and use by "#{MODEL_NAME}Serializer" in app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  type :user
  attributes :id, :created_at, :updated_at
end

# serialze
user = User.create!
ActiveModelSerializers::SerializableResource.new(
  user
).serializable_hash
# => {
#   user: {
#     id: id,
#     created_at: created_at,
#     updated_at: updated_at
#   }
# }
```

#### Alba

```rb
# Infer and use by "#{MODEL_NAME}Resource"
# In app/resources/user_resource.rb
class UserResource
  include Alba::Resource
  attributes :id, :created_at, :updated_at
end

# serialze
user = User.create!
UserResource.new(user).serializable_hash
# => {
#   id: id,
#   created_at: created_at,
#   updated_at: updated_at,
# }

# If want `user key`
class UserResource
  include Alba::Resource
  root_key :user # Call root_key method like ActiveModel::Serializer#type
  attributes :id, :created_at, :updated_at
end

# serialze
user = User.create!
JSON.parse UserResource.new(user).serialize # ！！！！serializable_hash does not support root key！！！ Must use JSON.parse and serialize
# => {
#   "user"=>{
#     "id"=>id,
#     "created_at"=>created_at,
#     "updated_at"=>updated_at
#   }
# }
# If want symbolize keys with #deep_symbolize_keys in Rails
user = User.create!
JSON.parse(UserResource.new(user).serialize).deep_symbolize_keys
# => {
#   user: {
#     id: id,
#     created_at: created_at,
#     updated_at: updated_at
#   }
# }
```

## 2. Complex serialization

### Serialize collections

#### ActiveModelSerializer

```rb
class UserSerializer < ActiveModel::Serializer
  type :user
  attributes :id, :created_at, :updated_at
end
3.times { User.create! }
users = User.limit 3
ActiveModelSerializers::SerializableResource.new(
  users,
  adapter: :attributes # Comment out this line if you want users key
  # Want to specified key to call with root: args
).serializable_hash
# => [{:id=>1, :created_at=>created_at, :updated_at=>updated_at},
#    {:id=>2, :created_at=>created_at, :updated_at=>updated_at},
#    {:id=>3, :created_at=>created_at, :updated_at=>updated_at}]
```

#### Alba

```rb
class UserResource
  include Alba::Resource
  attributes :id, :created_at, :updated_at
end
3.times { User.create! }
users = User.limit 3
UserResource.new(users).serializable_hash
# =>[{:id=>1, :created_at=>created_at, :updated_at=>updated_at},
#    {:id=>2, :created_at=>created_at, :updated_at=>updated_at},
#    {:id=>3, :created_at=>created_at, :updated_at=>updated_at}]
# or
JSON.parse UserResource.new(users).serialize(root_key: :users)
# => {"users"=>
#   [{"id"=>1, "created_at"=>created_at, "updated_at"=>updated_at},
#    {"id"=>2, "created_at"=>created_at, "updated_at"=>updated_at},
#    {"id"=>3, "created_at"=>created_at, "updated_at"=>updated_at}]}
```

### Nested serialization

#### ActiveModelSerializer

```rb
class ProfileSerializer < ActiveModel::Serializer
  type :profile
  attributes :email
end

class ArticleSerializer < ActiveModel::Serializer
  type :article
  attributes :title, :body
end

class UserSerializer < ActiveModel::Serializer
  type :user
  attributes :id, :created_at, :updated_at
  has_one :profile, serializer: ProfileSerializer # For has_one relation
  has_many :articles, serializer: ArticleSerializer # For has_many relation
end
user = User.create!
user.craete_profile! email: email
user.articles.create! title: title, body: body
ActiveModelSerializers::SerializableResource.new(
  user
).serializable_hash
# => {
#   :user=> {
#     :id=>1,
#     :created_at=>created_at,
#     :updated_at=>updated_at,
#     :profile=> {
#       :email=>email
#     },
#     :articles => [
#       {
#         :title=>title,
#         :body=>body
#       }
#     ]
#   }
# }
```

#### Alba

```rb
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
  one :profile, resource: ProfileResource # For has_one relation
  many :articles, resource: ArticleResource # For has_many relation
end

user = User.create!
user.craete_profile! email: email
user.articles.create! title: title, body: body
UserResource.new(user).serializable_hash
# => {
#   :id=>1,
#   :created_at=>created_at,
#   :updated_at=>updated_at,
#   :profile=> {
#     :email=>email
#   },
#   :articles => [
#     {
#       :title=>title,
#       :body=>body
#     }
#   ]
# }
```

### Serialize with custom serializer

#### ActiveModelSerializer

```rb
class CustomUserSerializer < ActiveModel::Serializer
  type :user
  attribute :email do
    object.profile.email
  end
end

# serialze
user = User.create!
user.craete_profile! email: email
ActiveModelSerializers::SerializableResource.new(
  user,
  serializer: ::CustomUserSerializer # Call with serializer arg
).serializable_hash
# => {
#   user: {
#     email: email
#   }
# }
```

#### Alba

```rb
class CustomUserResource
  include Alba::Resource
  root_key :user
  attribute :email do
    object.profile.email
  end
end

# serialze
user = User.create!
user.craete_profile! email: email
CustomUserResource.new(user).serializable_hash
# => {
#   email: email
# }
```

### Passing arbitrary options to a serializer

#### ActiveModelSerializer

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
user = User.create!
ActiveModelSerializers::SerializableResource.new(
  user,
  given_params: { a: :b } # Give with your favorite keyword argument
).serializable_hash
# => {
#   :id=>1,
#   :created_at=>created_at,
#   :updated_at=>updated_at,
#   :custom_params=>{
#     :given_params=>{
#       :a=>:b
#     }
#   }
# }
```

#### Alba

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
user = User.create!
UserResource.new(
  user,
  params: { a: :b } # Give with :params keyword argument
).serializable_hash
# => {
#   :id=>1,
#   :created_at=>created_at,
#   :updated_at=>updated_at,
#   :custom_params=>{
#     :a=>:b
#   }
# }
```

## 3. Unsupported features

- [RelationshipLinks](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/howto/add_relationship_links.md)
- [PaginationLinks](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/howto/add_pagination_links.md)
- [Logging](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/general/logging.md)
- [Caching](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/general/caching.md)
- [Rendering](https://github.com/rails-api/active_model_serializers/blob/v0.10.6/docs/general/rendering.md)
