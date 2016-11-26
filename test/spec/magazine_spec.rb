require 'spec_helper'
require 'faraday'
require 'json'

RSpec.describe 'magazines' do
  let(:springs) { Faraday.new(:url => "http://localhost:8080/exist/restxq/springs/")  }
  
  it 'returns a list of magazines as JSON' do
    response = springs.get do |request|
      request.url 'magazines'
      request.headers['Accept'] = 'application/json'
    end
    json = JSON.parse(response.body)
    expect(json['magazine'].count).not_to eq(0)
  end

  it 'returns a list of magazines as CSV' do
    response = springs.get do |request|
      request.url 'magazines'
      request.headers['Accept'] = 'text/csv'
    end
    expect(response.body).not_to be_empty()
  end

  it 'returns a representation of a particular magazine as JSON' do
    response = springs.get do |request|
      request.url 'magazines/bmtnaap'
      request.headers['Accept'] = 'application/json'
    end
    json = JSON.parse(response.body)
    expect(json['bmtnid']).to eq('bmtnaap')
    expect(json['primaryTitle']).to eq('Broom: An International Magazine of the Arts')
    expect(json['issues']['issue'].count).to eq(21)
  end
end
