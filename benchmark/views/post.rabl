# frozen_string_literal: true

object @post

attributes :id, :body

child :comments do
  attributes :id, :body
end

node(:commenter_names) { |post| post.commenters.pluck(:name) }
