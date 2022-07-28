require 'spec_helper'

RSpec.describe('Alba JSONAPI compatibility: key transformation') do
  let(:actor) { Actor.fake }
  let(:params) { {} }
  let(:serialized) do
    JSON.parse(CamelCaseActorSerializer.new(actor, params: params).serialize)
  end

  before { Alba.enable_inference!(with: :active_support) }
  after { Alba.disable_inference! }

  describe 'camel case key tranformation' do
    it do
      expect(serialized['data']).to(have_id(actor.uid))
      expect(serialized['data']).to(have_type('UserActor'))
      expect(serialized['data']).to(have_attribute('FirstName'))
      expect(serialized['data']).to(have_relationship('PlayedMovies'))
      expect(serialized['data']).to(have_link('MovieUrl').with_value(nil))
    end
  end
end
