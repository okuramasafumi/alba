require_relative 'prep'
require 'alba'

Alba.inflector = :active_support

class AlbaCommentResource
  include ::Alba::Resource
  attributes :id, :body
end

class AlbaPostResource
  include ::Alba::Resource
  attributes :id, :body
  attribute :commenter_names do |post|
    post.commenters.pluck(:name)
  end
  many :comments, resource: AlbaCommentResource
end

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

1000.times do
  AlbaPostResource.new(posts).serialize
end
