require 'active_support'
require 'active_support/cache'

class Actor < User
  attr_accessor :movies, :movie_ids

  def self.fake(id = nil)
    faked = super(id)
    faked.movies = []
    faked.movie_ids = []
    faked
  end

  def movie_urls
    {
      movie_url: movies[0]&.url
    }
  end
end

class ActorSerializer < UserSerializer
  set_type :actor

  attributes :email, if: ->(_object) { params[:conditionals_off].nil? }

  has_many :movies, resource: 'MovieSerializer', key: :played_movies, links: :movie_urls, if: ->(_object) { params[:conditionals_off].nil? }
end

class CamelCaseActorSerializer
  include Alba::JSONAPI

  transform_keys :camel

  set_id :uid
  set_type :user_actor
  attributes :first_name

  link :movie_url do
    object.movie_urls.values[0]
  end

  has_many :movies, resource: 'MovieSerializer', key: :played_movies
  # has_many(
  #   :played_movies,
  #   serializer: :movie
  # ) do |object|
  #   object.movies
  # end
end

class BadMovieSerializerActorSerializer < ActorSerializer
  has_many :played_movies, resource: :bad # , object_method_name: :movies
end

module Cached
  class ActorSerializer < ::ActorSerializer
    # TODO: Fix this, the serializer gets cached on inherited classes...
    # has_many :played_movies, serializer: :movie do |object|
    # object.movies
    # end

    # cache_options(store: ActiveSupport::Cache::MemoryStore.new, namespace: 'test')
  end
end

# module Instrumented
#   class ActorSerializer < ::ActorSerializer
#     include ::JSONAPI::Serializer::Instrumentation
#   end
# end
