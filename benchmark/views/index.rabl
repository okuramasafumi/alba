# frozen_string_literal: true

collection @posts
attributes :id, :body
child(:comments) { attributes :id, :body }
node(:commenter_names) { |post| post.commenters.pluck(:name) }
