class Movie
  attr_accessor(:id, :name, :year, :actor_or_user, :actors, :actor_ids, :polymorphics, :owner, :owner_id)

  def self.fake(id = nil)
    faked = new
    faked.id = id || SecureRandom.uuid
    faked.name = FFaker::Movie.title
    faked.year = FFaker::Vehicle.year
    faked.actors = []
    faked.actor_ids = []
    faked.polymorphics = []
    faked
  end

  def url(obj = nil)
    @url ||= FFaker::Internet.http_url
    return @url if obj.nil?

    "#{@url}?#{obj.hash}"
  end

  def owner=(ownr)
    @owner = ownr
    @owner_id = ownr.uid
  end

  def actors=(acts)
    @actors = acts
    @actor_ids = actors.map do |actor|
      actor.movies << self
      actor.uid
    end
  end
end

class MovieSerializer
  include Alba::JSONAPI

  root_key :movie, :movies

  set_type :movie

  attribute :released_in_year, &:year
  attributes :name
  attribute :release_year do |object|
    object.year
  end

  link :self do |movie|
    movie.url
  end

  one :owner, resource: UserSerializer

  # belongs_to :actor_or_user, id_method_name: :uid, polymorphic: {Actor => :actor, User => :user}

  has_many(
    :actors,
    meta: proc { |record, _| {count: record.actors.length} },
    links: {
      actors_self: proc { |movie| movie.url },
      related: proc { |movie|
                 movie.url(movie)
               }
    },
    resource: ActorSerializer
  )
  has_one(:owner, key: :creator, id_method_name: :uid, resource: UserSerializer)
  has_many(
    :polymorphics,
    key: :actors_and_users,
    id_method_name: :uid,
    polymorphic: {Actor => :actor, User => :user},
    resource: lambda { |user|
      user.is_a?(Actor) ? ActorSerializer : UserSerializer
    }
  )

  has_many(
    :polymorphics,
    key: :dynamic_actors_and_users,
    id_method_name: :uid,
    polymorphic: {Actor => :actor, User => :user},
    resource: lambda { |user|
      user.is_a?(Actor) ? ActorSerializer : UserSerializer
    }
  )

  # has_many(
  #   :auto_detected_actors_and_users,
  #   id_method_name: :uid
  # ) do |obj|
  #   obj.polymorphics
  # end
end

module Cached
  class MovieSerializer < ::MovieSerializer
    # cache_options(store: ActorSerializer.cache_store_instance, namespace: 'test')

    # has_one(
    #   :creator,
    #   id_method_name: :uid,
    #   serializer: :actor,
    #   # TODO: Remove this undocumented option.
    #   #   Delegate the caching to the serializer exclusively.
    #   cached: false
    # ) do |obj|
    #   obj.owner
    # end
  end
end
