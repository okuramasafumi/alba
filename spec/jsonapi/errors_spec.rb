require 'spec_helper'

RSpec.describe('Alba JSONAPI compatibility: errors') do
  let(:actor) { Actor.fake }
  let(:params) { {} }

  describe 'with errors' do
    it do
      skip 'Consider this more'
      expect do
        BadMovieSerializerActorSerializer.new(actor, include: ['played_movies'])
      end.to(raise_error(
               NameError, /cannot resolve a serializer class for 'bad'/
             ))
    end

    it do
      skip 'Consider this more'
      expect { ActorSerializer.new(actor, include: ['bad_include']) }
        .to(raise_error(
              JSONAPI::Serializer::UnsupportedIncludeError, /bad_include is not specified as a relationship/
            ))
    end
  end
end
