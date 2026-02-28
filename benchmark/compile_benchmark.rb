# frozen_string_literal: true

# Simple benchmark to compare Alba performance with and without compile

require_relative '../lib/alba'
require 'json'
require 'time'
require 'benchmark/ips'

# Simple model class
class User
  attr_accessor :id, :name, :email, :created_at

  def initialize(id:, name:, email:, created_at:)
    @id = id
    @name = name
    @email = email
    @created_at = created_at
  end
end

class Comment
  attr_accessor :id, :body, :user_id

  def initialize(id:, body:, user_id:)
    @id = id
    @body = body
    @user_id = user_id
  end
end

class Post
  attr_accessor :id, :title, :body, :user, :comments

  def initialize(id:, title:, body:, user:, comments:)
    @id = id
    @title = title
    @body = body
    @user = user
    @comments = comments
  end
end

# Resource classes WITHOUT compile
module NonCompiled
  class UserResource
    include Alba::Resource

    attributes :id, :name, :email

    attribute :created_at do |user|
      user.created_at.iso8601
    end
  end

  class CommentResource
    include Alba::Resource

    attributes :id, :body, :user_id
  end

  class PostResource
    include Alba::Resource

    attributes :id, :title, :body
    one :user, resource: UserResource
    many :comments, resource: CommentResource
  end
end

# Reset to avoid any side effects
Alba.reset!

# Resource classes WITH compile
module Compiled
  class UserResource
    include Alba::Resource

    attributes :id, :name, :email

    attribute :created_at do |user|
      user.created_at.iso8601
    end
  end

  class CommentResource
    include Alba::Resource

    attributes :id, :body, :user_id
  end

  class PostResource
    include Alba::Resource

    attributes :id, :title, :body
    one :user, resource: UserResource
    many :comments, resource: CommentResource
  end
end

# Compile resources
Alba.compile

# Create test data
user = User.new(id: 1, name: 'John Doe', email: 'john@example.com', created_at: Time.now)
comments = (1..10).map { |i| Comment.new(id: i, body: "Comment #{i}", user_id: 1) }
post = Post.new(id: 1, title: 'Hello World', body: 'This is a test post', user: user, comments: comments)
posts = (1..100).map { |i| Post.new(id: i, title: "Post #{i}", body: "Body #{i}", user: user, comments: comments) }

# Verify output is the same
non_compiled_output = NonCompiled::PostResource.new(post).serialize
compiled_output = Compiled::PostResource.new(post).serialize

puts "Output verification:"
puts "Non-compiled and compiled outputs match: #{non_compiled_output == compiled_output}"
puts
puts "Single post output:"
puts compiled_output
puts

# Run benchmarks
puts "=" * 60
puts "SINGLE RESOURCE BENCHMARK"
puts "=" * 60
puts

Benchmark.ips do |x|
  x.report('Alba (non-compiled)') { NonCompiled::PostResource.new(post).serialize }
  x.report('Alba (compiled)') { Compiled::PostResource.new(post).serialize }
  x.compare!
end

puts
puts "=" * 60
puts "COLLECTION BENCHMARK (100 posts)"
puts "=" * 60
puts

Benchmark.ips do |x|
  x.report('Alba (non-compiled)') { NonCompiled::PostResource.new(posts).serialize }
  x.report('Alba (compiled)') { Compiled::PostResource.new(posts).serialize }
  x.compare!
end

# Memory benchmark if available
begin
  require 'benchmark/memory'

  puts
  puts "=" * 60
  puts "MEMORY BENCHMARK (single post)"
  puts "=" * 60
  puts

  Benchmark.memory do |x|
    x.report('Alba (non-compiled)') { NonCompiled::PostResource.new(post).serialize }
    x.report('Alba (compiled)') { Compiled::PostResource.new(post).serialize }
    x.compare!
  end

  puts
  puts "=" * 60
  puts "MEMORY BENCHMARK (100 posts)"
  puts "=" * 60
  puts

  Benchmark.memory do |x|
    x.report('Alba (non-compiled)') { NonCompiled::PostResource.new(posts).serialize }
    x.report('Alba (compiled)') { Compiled::PostResource.new(posts).serialize }
    x.compare!
  end
rescue LoadError
  puts
  puts "Note: benchmark-memory not available, skipping memory benchmarks"
end
