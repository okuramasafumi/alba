# --- Bundle dependencies ---

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "active_model_serializers"
  gem "activerecord", "6.1.3"
  gem "alba", path: '../'
  gem "benchmark-ips"
  gem "benchmark-memory"
  gem "blueprinter"
  gem "fast_serializer_ruby"
  gem "jbuilder"
  gem 'turbostreamer'
  gem "jserializer"
  gem "multi_json"
  gem "panko_serializer"
  gem "pg"
  gem "primalize"
  gem "oj"
  gem "representable"
  gem "simple_ams"
  gem "sqlite3"
end

# --- Test data model setup ---

require "pg"
require "active_record"
require "active_record/connection_adapters/postgresql_adapter"
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
