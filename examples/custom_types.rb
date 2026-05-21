# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

require 'time'

Alba.register_type(:iso8601, converter: ->(time) { time.iso8601(3) }, auto_convert: true)
Alba.register_type(:short_date, converter: ->(date) { date.strftime('%F') }, auto_convert: true)

class Event
  attr_reader :id, :name, :created_at, :starts_on

  def initialize(id, name, created_at, starts_on)
    @id = id
    @name = name
    @created_at = created_at
    @starts_on = starts_on
  end
end

class EventResource
  include Alba::Resource

  attributes :id, :name, created_at: :iso8601, starts_on: :short_date
end

event = Event.new(1, 'Release', Time.new(2026, 5, 21, 10, 30, 15, '+09:00'), Time.new(2026, 6, 1, 0, 0, 0, '+09:00'))

puts EventResource.new(event).serialize
