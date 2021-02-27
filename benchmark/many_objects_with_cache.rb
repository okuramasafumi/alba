# Benchmark script to run varieties of JSON serializers
# Fetch Alba from local, otherwise fetch latest from RubyGems

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "activerecord", "6.1.3"
  gem "sqlite3"
  gem "jbuilder"
  gem "active_model_serializers"
  gem "blueprinter"
  gem "representable"
  gem "alba", path: '../'
  gem "oj"
  gem "multi_json"
  gem "activesupport", "6.1.3"
end

require "active_record"
require "sqlite3"
require "logger"
require "oj"
Oj.optimize_rails

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
# ActiveRecord::Base.logger = Logger.new(STDOUT)

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

require "alba"
Alba.backend = :oj
Alba.cache_store = :memory

class AlbaCommentResource
  include ::Alba::Resource
  attributes :id, :body
end

class AlbaPostResource
  include ::Alba::Resource
  attributes :id, :body
  many :comments, resource: AlbaCommentResource
  attribute :commenter_names do |post|
    post.commenters.pluck(:name)
  end
end

require "jbuilder"
class Post
  def to_builder
    Jbuilder.new do |post|
      post.call(self, :id, :body, :comments, :commenter_names)
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

require "active_model_serializers"

class AMSCommentSerializer < ActiveModel::Serializer
  attributes :id, :body
end

class AMSPostSerializer < ActiveModel::Serializer
  attributes :id, :body
  has_many :comments, serializer: AMSCommentSerializer
  attribute :commenter_names
  def commenter_names
    object.commenters.pluck(:name)
  end
end

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

require "representable"

class CommentRepresenter < Representable::Decorator
  include Representable::JSON

  property :id
  property :body
end

class PostRepresenter < Representable::Decorator
  include Representable::JSON

  property :id
  property :body
  property :commenter_names
  collection :comments

  def commenter_names
    commenters.pluck(:name)
  end
end

posts = []
1000.times do |i|
  post = Post.create!(body: "post#{i}")
  user1 = User.create!(name: "John#{i}")
  user2 = User.create!(name: "Jane#{i}")
  post.comments.create!(commenter: user1, body: 'Comment1')
  post.comments.create!(commenter: user2, body: 'Comment2')
  post.reload
  posts << post
end

alba = Proc.new { |item| AlbaPostResource.new(item).serialize }
jbuilder = Proc.new { |item| item.to_builder.target! }
ams = Proc.new { |item| AMSPostSerializer.new(item, {}).to_json }
rails = Proc.new { |item| ActiveSupport::JSON.encode(item.serializable_hash(include: :comments)) }
blueprinter = Proc.new { |item| PostBlueprint.render(item) }
representable = Proc.new { |item| PostRepresenter.new(item).to_json }
alba_inline = Proc.new do |item|
  Alba.serialize(item) do
    attributes :id, :body
    attribute :commenter_names do |post|
      post.commenters.pluck(:name)
    end
    many :comments do
      attributes :id, :body
    end
  end
end
[alba, jbuilder, ams, rails, blueprinter, representable, alba_inline].each {|x| puts x.call(posts.first) }

require 'benchmark'
time = 1000
Benchmark.bmbm do |x|
  x.report(:alba) { time.times {|i| alba.call(posts[i])} }
  x.report(:jbuilder) { time.times {|i| jbuilder.call(posts[i])} }
  x.report(:ams) { time.times {|i| ams.call(posts[i])} }
  x.report(:rails) { time.times {|i| rails.call(posts[i])} }
  x.report(:blueprinter) { time.times {|i| blueprinter.call(posts[i])} }
  x.report(:representable) { time.times {|i| representable.call(posts[i])} }
  x.report(:alba_inline) { time.times {|i| alba_inline.call(posts[i])} }
end
