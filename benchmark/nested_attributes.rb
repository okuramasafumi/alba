# Benchmark script to measure what a nested attribute costs.
#
# Each pair of resources below serializes exactly the same JSON, once with the nested hash built by hand in a plain
# attribute and once with `nested_attribute`, so whatever separates the two is what the nested attribute costs.

require_relative 'prep'

require 'alba'

class CommentResource
  include Alba::Resource
  attributes :id, :body
end

# --- The nested hash built by hand ---

class ManualPostResource
  include Alba::Resource
  attributes :id
  attribute(:details) { |post| {body: post.body} }
end

class ManualPostWithCommentsResource
  include Alba::Resource
  attributes :id
  attribute(:details) { |post| {body: post.body, comments: CommentResource.new(post.comments).serializable_hash} }
end

# --- The same JSON, through a nested attribute ---

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
    many :comments, resource: CommentResource
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

manual_attribute = proc { ManualPostResource.new(posts).serialize }
nested_attribute = proc { NestedPostResource.new(posts).serialize }
manual_association = proc { ManualPostWithCommentsResource.new(posts).serialize }
nested_association = proc { NestedPostWithCommentsResource.new(posts).serialize }

raise 'manual and nested must serialize the same JSON' unless manual_attribute.call == nested_attribute.call
raise 'manual and nested must serialize the same JSON' unless manual_association.call == nested_association.call

benchmark_body = lambda do |x|
  x.report(:attribute_manual, &manual_attribute)
  x.report(:attribute_nested, &nested_attribute)
  x.report(:association_manual, &manual_association)
  x.report(:association_nested, &nested_association)

  x.compare!
end

require 'benchmark/ips'
Benchmark.ips(&benchmark_body)

require 'benchmark/memory'
Benchmark.memory(&benchmark_body)
