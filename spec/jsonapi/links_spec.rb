require 'spec_helper'

RSpec.describe('Alba JSONAPI compatibility: links') do
  let(:movie) do
    faked = Movie.fake
    faked.actors = [Actor.fake]
    faked
  end
  let(:links) { {} }
  let(:serialized) do
    JSON.parse(MovieSerializer.new(movie, links: links, within: {actors: nil}).serialize)
  end

  describe 'links' do
    it do
      expect(serialized['data']).to(have_link('self').with_value(movie.url))
      expect(serialized['data']['relationships']['actors']).to(have_link('actors_self').with_value(movie.url))
      expect(serialized['data']['relationships']['actors']).to(have_link('related').with_value(movie.url(movie)))
    end

    context 'with included records' do
      let(:serialized) do
        JSON.parse(ActorSerializer.new(movie.actors[0], within: :movies).serialize)
      end

      it do
        expect(serialized['data']['relationships']['played_movies']).to(have_link('movie_url').with_value(movie.url))
      end
    end

    context 'with root link' do
      let(:links) do
        {'root_link' => FFaker::Internet.http_url}
      end

      it do
        expect(serialized).to(have_link('root_link').with_value(links['root_link']))
      end
    end
  end
end
