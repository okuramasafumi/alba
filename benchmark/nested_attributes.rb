# Benchmark script to measure what a nested attribute costs.
#
# Each pair of resources below serializes the same attributes, once declared directly on the resource
# and once declared inside a nested attribute, so whatever separates the two is what nesting costs.

require_relative 'prep'

require 'alba'

# --- Attributes on the resource ---

class FlatCommentResource
  include Alba::Resource
  attributes :id, :body
end

class FlatPostResource
  include Alba::Resource
  attributes :id, :body
end

class FlatPostWithCommentsResource
  include Alba::Resource
  attributes :id, :body
  many :comments, resource: FlatCommentResource
end

# --- The same attributes, in a nested attribute ---

class NestedCommentResource
  include Alba::Resource
  attributes :id, :body
end

class NestedPostResource
  include Alba::Resource
  attributes :id

  nested_attribute :details do
    attributes :body
  end
end

class NestedPostWithCommentsResource
  include Alba::Resource
  attributes :id

  nested_attribute :details do
    attributes :body
    many :comments, resource: NestedCommentResource
  end
end

# --- Test data creation ---

100.times do |i|
  post = Post.create!(body: "post#{i}")
  user1 = User.create!(name: "John#{i}")
  user2 = User.create!(name: "Jane#{i}")
  10.times do |n|
    post.comments.create!(commenter: user1, body: "Comment1_#{i}_#{n}")
    post.comments.create!(commenter: user2, body: "Comment2_#{i}_#{n}")
  end
end

posts = Post.all.includes(:comments, :commenters)

flat_attribute = proc { FlatPostResource.new(posts).serialize }
nested_attribute = proc { NestedPostResource.new(posts).serialize }
flat_association = proc { FlatPostWithCommentsResource.new(posts).serialize }
nested_association = proc { NestedPostWithCommentsResource.new(posts).serialize }

benchmark_body = lambda do |x|
  x.report(:attribute_flat, &flat_attribute)
  x.report(:attribute_nested, &nested_attribute)
  x.report(:association_flat, &flat_association)
  x.report(:association_nested, &nested_association)

  x.compare!
end

require 'benchmark/ips'
Benchmark.ips(&benchmark_body)

require 'benchmark/memory'
Benchmark.memory(&benchmark_body)
