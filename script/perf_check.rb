# Benchmark script to run varieties of JSON serializers
# Fetch Alba from local, otherwise fetch latest from RubyGems
# exit(status)

# --- Bundle dependencies ---

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "activerecord", "~> 6.1.3"
  gem "alba", path: '../'
  gem "benchmark-ips"
  gem "blueprinter"
  gem "jbuilder"
  gem "multi_json"
  gem "oj"
  gem "sqlite3"
end

# --- Test data model setup ---

require "active_record"
require "oj"
require "sqlite3"
Oj.optimize_rails

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :body
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
    t.string :body
    t.integer :commenter_id
  end

  create_table :users, force: true do |t|
    t.string :name
  end
end

class Post < ActiveRecord::Base
  has_many :comments
  has_many :commenters, through: :comments, class_name: 'User', source: :commenter

  def attributes
    {id: nil, body: nil, commenter_names: commenter_names}
  end

  def commenter_names
    commenters.pluck(:name)
  end
end

class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :commenter, class_name: 'User'

  def attributes
    {id: nil, body: nil}
  end
end

class User < ActiveRecord::Base
  has_many :comments
end

# --- Alba serializers ---

require "alba"

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

# --- Blueprint serializers ---

require "blueprinter"

class CommentBlueprint < Blueprinter::Base
  fields :id, :body
end

class PostBlueprint < Blueprinter::Base
  fields :id, :body, :commenter_names
  association :comments, blueprint: CommentBlueprint

  def commenter_names
    commenters.pluck(:name)
  end
end

# --- JBuilder serializers ---

require "jbuilder"

class Post
  def to_builder
    Jbuilder.new do |post|
      post.call(self, :id, :body, :commenter_names, :comments)
    end
  end

  def commenter_names
    commenters.pluck(:name)
  end
end

class Comment
  def to_builder
    Jbuilder.new do |comment|
      comment.call(self, :id, :body)
    end
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

posts = Post.all.to_a

# --- Store the serializers in procs ---

alba = Proc.new { AlbaPostResource.new(posts).serialize }
blueprinter = Proc.new { PostBlueprint.render(posts) }
jbuilder = Proc.new do
  Jbuilder.new do |json|
    json.array!(posts) do |post|
      json.post post.to_builder
    end
  end.target!
end

# --- Run the benchmarks ---

require 'benchmark/ips'
result = Benchmark.ips do |x|
  x.report(:alba, &alba)
  x.report(:blueprinter, &blueprinter)
  x.report(:jbuilder, &jbuilder)
end

entries = result.entries.map {|entry| [entry.label, entry.iterations]}
alba_ips = entries.find {|e| e.first == :alba }.last
blueprinter_ips = entries.find {|e| e.first == :blueprinter }.last
jbuidler_ips = entries.find {|e| e.first == :jbuilder }.last
# Alba should be as fast as jbuilder and faster than blueprinter
alba_is_fast_enough = (alba_ips - jbuidler_ips) > -10.0 && (alba_ips - blueprinter_ips) > 10.0
exit(alba_is_fast_enough)
