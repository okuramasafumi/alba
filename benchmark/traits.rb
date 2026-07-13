# Benchmark script to measure what a trait costs.
#
# Each pair of resources below serializes exactly the same JSON, once with the attributes declared on the resource
# and once with the very same attributes declared in a trait, so whatever separates the two is what the trait costs.

require_relative 'prep'

require 'alba'

# --- Attributes on the resource ---

class InlineCommentResource
  include Alba::Resource
  attributes :id, :body
end

class InlinePostResource
  include Alba::Resource
  attributes :id, :body
  attribute(:commenter_names) { |post| post.commenters.pluck(:name) }
  many :comments, resource: InlineCommentResource
end

# --- The same attributes, in a trait ---

class TraitCommentResource
  include Alba::Resource
  attributes :id, :body
end

class TraitPostResource
  include Alba::Resource
  attributes :id, :body

  trait :with_comments do
    attribute(:commenter_names) { |post| post.commenters.pluck(:name) }
    many :comments, resource: TraitCommentResource
  end
end

# --- A trait carrying a plain attribute, which is where a resource pays the most for one ---

class InlineBodySizeResource
  include Alba::Resource
  attributes :id, :body
  attribute(:body_size) { |post| post.body.size }
end

class TraitBodySizeResource
  include Alba::Resource
  attributes :id, :body

  trait :with_body_size do
    attribute(:body_size) { |post| post.body.size }
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

inline_association = proc { InlinePostResource.new(posts).serialize }
trait_association = proc { TraitPostResource.new(posts, with_traits: :with_comments).serialize }
inline_attribute = proc { InlineBodySizeResource.new(posts).serialize }
trait_attribute = proc { TraitBodySizeResource.new(posts, with_traits: :with_body_size).serialize }

raise 'inline and trait must serialize the same JSON' unless inline_association.call == trait_association.call
raise 'inline and trait must serialize the same JSON' unless inline_attribute.call == trait_attribute.call

benchmark_body = lambda do |x|
  x.report(:attribute_inline, &inline_attribute)
  x.report(:attribute_trait, &trait_attribute)
  x.report(:association_inline, &inline_association)
  x.report(:association_trait, &trait_association)

  x.compare!
end

require 'benchmark/ips'
Benchmark.ips(&benchmark_body)

require 'benchmark/memory'
Benchmark.memory(&benchmark_body)
