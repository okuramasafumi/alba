# Benchmark script to run varieties of JSON serializers
# Fetch Alba from local, otherwise fetch latest from RubyGems

# --- Bundle dependencies ---

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "active_model_serializers"
  gem "activerecord", "6.1.3"
  gem "alba", path: '../'
  gem "benchmark-ips"
  gem "blueprinter"
  gem "jbuilder"
  gem "jsonapi-serializer" # successor of fast_jsonapi
  gem "multi_json"
  gem "primalize"
  gem "oj"
  gem "representable"
  gem "sqlite3"
end

# --- Test data model setup ---

require "active_record"
require "logger"
require "oj"
require "sqlite3"
Oj.optimize_rails

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
# ActiveRecord::Base.logger = Logger.new($stdout)

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

# --- ActiveModelSerializer serializers ---

require "active_model_serializers"

class AMSCommentSerializer < ActiveModel::Serializer
  attributes :id, :body
end

class AMSPostSerializer < ActiveModel::Serializer
  attributes :id, :body
  attribute :commenter_names
  has_many :comments, serializer: AMSCommentSerializer

  def commenter_names
    object.commenters.pluck(:name)
  end
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

# --- JSONAPI:Serializer serializers / (successor of fast_jsonapi) ---

class JsonApiStandardCommentSerializer
  include JSONAPI::Serializer

  attribute :id
  attribute :body
end

class JsonApiStandardPostSerializer
  include JSONAPI::Serializer

  # set_type :post  # optional
  attribute :id
  attribute :body
  attribute :commenter_names

  attribute :comments do |post|
    post.comments.map { |comment| JsonApiSameFormatCommentSerializer.new(comment) }
  end
end

# --- JSONAPI:Serializer serializers that format the code the same flat way as the other gems here ---

# code to convert from JSON:API output to "flat" JSON, like the other serializers build
class JsonApiSameFormatSerializer
  include JSONAPI::Serializer

  def as_json(*_options)
    hash = serializable_hash

    if hash[:data].is_a? Hash
      hash[:data][:attributes]

    elsif hash[:data].is_a? Array
      hash[:data].pluck(:attributes)

    elsif hash[:data].nil?
      { }

    else
      raise "unexpected data type #{hash[:data].class}"
    end
  end
end

class JsonApiSameFormatCommentSerializer < JsonApiSameFormatSerializer
  attribute :id
  attribute :body
end

class JsonApiSameFormatPostSerializer < JsonApiSameFormatSerializer
  attribute :id
  attribute :body
  attribute :commenter_names

  attribute :comments do |post|
    post.comments.map { |comment| JsonApiSameFormatCommentSerializer.new(comment) }
  end
end

# --- Primalize serializers ---
#
class PrimalizeCommentResource < Primalize::Single
  attributes id: integer, body: string
end

class PrimalizePostResource < Primalize::Single
  alias post object

  attributes(
    id: integer,
    body: string,
    comments: array(primalize(PrimalizeCommentResource)),
    commenter_names: array(string),
  )

  def commenter_names
    post.commenters.pluck(:name)
  end
end

# --- Representable serializers ---

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

# --- Test data creation ---

post = Post.create!(body: 'post')
user1 = User.create!(name: 'John')
user2 = User.create!(name: 'Jane')
post.comments.create!(commenter: user1, body: 'Comment1')
post.comments.create!(commenter: user2, body: 'Comment2')
post.reload

# --- Store the serializers in procs ---

alba = Proc.new { AlbaPostResource.new(post).serialize }
alba_inline = Proc.new do
  Alba.serialize(post) do
    attributes :id, :body
    attribute :commenter_names do |post|
      post.commenters.pluck(:name)
    end
    many :comments do
      attributes :id, :body
    end
  end
end
ams = Proc.new { AMSPostSerializer.new(post, {}).to_json }
blueprinter = Proc.new { PostBlueprint.render(post) }
jbuilder = Proc.new { post.to_builder.target! }
jsonapi = proc { JsonApiStandardPostSerializer.new(post).to_json }
jsonapi_same_format = proc { JsonApiSameFormatPostSerializer.new(post).to_json }
primalize = proc { PrimalizePostResource.new(post).to_json }
rails = Proc.new { ActiveSupport::JSON.encode(post.serializable_hash(include: :comments)) }
representable = Proc.new { PostRepresenter.new(post).to_json }

# --- Execute the serializers to check their output ---

puts "Serializer outputs ----------------------------------"
{
  alba: alba,
  alba_inline: alba_inline,
  ams: ams,
  blueprinter: blueprinter,
  jbuilder: jbuilder, # different order
  jsonapi: jsonapi, # nested JSON:API format
  jsonapi_same_format: jsonapi_same_format,
  primalize: primalize,
  rails: rails,
  representable: representable
}.each { |name, serializer| puts "#{name.to_s.ljust(24, ' ')} #{serializer.call}" }

# --- Run the benchmarks ---

require 'benchmark'
time = 1000
Benchmark.bmbm do |x|
  x.report(:alba) { time.times(&alba) }
  x.report(:alba_inline) { time.times(&alba_inline) }
  x.report(:ams) { time.times(&ams) }
  x.report(:blueprinter) { time.times(&blueprinter) }
  x.report(:jbuilder) { time.times(&jbuilder) }
  x.report(:jsonapi) { time.times(&jsonapi) }
  x.report(:jsonapi_same_format) { time.times(&jsonapi_same_format) }
  x.report(:primalize) { time.times(&primalize) }
  x.report(:rails) { time.times(&rails) }
  x.report(:representable) { time.times(&representable) }
end

require 'benchmark/ips'
Benchmark.ips do |x|
  x.report(:alba, &alba)
  x.report(:alba_inline, &alba_inline)
  x.report(:ams, &ams)
  x.report(:blueprinter, &blueprinter)
  x.report(:jbuilder, &jbuilder)
  x.report(:jsonapi, &jsonapi)
  x.report(:jsonapi_same_format, &jsonapi_same_format)
  x.report(:primalize, &primalize)
  x.report(:rails, &rails)
  x.report(:representable, &representable)

  x.compare!
end
