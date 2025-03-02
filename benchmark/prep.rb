# --- Test data model setup ---

RubyVM::YJIT.enable unless ENV["NO_YJIT"]
require "csv"
require "pg"
require "active_record"
require "active_record/connection_adapters/postgresql_adapter"
require "logger"
require "oj"
require "sqlite3"
Oj.optimize_rails unless ENV['NO_OJ_OPTIMIZE_RAILS']

puts 'Running benchmark with the following configuration:'
puts "YJIT: #{RubyVM::YJIT.enabled? ? 'enabled' : 'disabled'}"
puts "Oj.optimize_rails: #{ENV['NO_OJ_OPTIMIZE_RAILS'] ? 'disabled' : 'enabled'}"

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
