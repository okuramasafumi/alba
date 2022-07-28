require 'spec_helper'

RSpec.describe('Alba JSONAPI compatibility: meta') do
  let(:user) { User.fake }
  let(:meta) { {} }
  let(:serialized) do
    JSON.parse(UserSerializer.new(user, meta: meta).serialize)
  end

  it do
    expect(serialized['data']).to(have_meta('email_length' => user.email.size))
  end

  context 'with root meta' do
    let(:meta) do
      {'code' => FFaker::Internet.password}
    end

    it do
      expect(serialized).to(have_meta(meta))
    end
  end
end
