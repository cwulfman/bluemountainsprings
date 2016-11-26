require 'spec_helper'
require 'faraday'
require 'json'
require 'nokogiri'
require 'csv'

RSpec.describe 'contributions' do
  let(:springs) { Faraday.new(:url => "http://localhost:8080/exist/restxq/springs/")  }

  it 'returns a set of contributions as JSON' do
    response = springs.get do |request|
      request.url 'contributions'
      request.params['byline'] = 'Stevens'
      request.headers['Accept'] = 'application/json'
    end
    titles = JSON.parse(response.body)['contribution'].collect {|c| c['title'] }
    expect(response.body).not_to be_empty()
    expect(titles).to include("The Bird with the Coppery, Keen Claws")
  end

  it 'returns a set of contributions as TEI XML' do
    response = springs.get do |request|
      request.url 'contributions'
      request.params['byline'] = 'Stevens'
      request.headers['Accept'] = 'application/tei+xml'
    end
    xml = Nokogiri::XML(response.body)
    titles = xml.xpath('//tei:title/tei:seg/text()',
                       tei: 'http://www.tei-c.org/ns/1.0').collect { |title| title.to_s }
    expect(response.body).not_to be_empty()
    expect(titles).to include("Bird with the Coppery, Keen Claws")
  end
end
