require 'spec_helper'
require 'faraday'
require 'json'
require 'nokogiri'

RSpec.describe 'constituents' do
  let(:springs) { Faraday.new(:url => "http://localhost:8080/exist/restxq/springs/")  }

  it "Returns a list of issues constituents as JSON" do
    response = springs.get do |request|
      request.url 'constituents/bmtnaap_1921-11_01'
      request.headers['Accept'] = 'application/json'
    end
    json = JSON.parse(response.body)
    expect(json['constituents']['constituent'].count).to eq(57)
  end

  it "Returns status 400 if the requested resource does not exist" do
    response = springs.get do |request|
      request.url 'constituents/bmtnZZZ'
    end
    expect(response.status).to eq(400)
  end

  it "Returns magazines constituents as uris" do
    response = springs.get do |request|
      request.url 'constituents/bmtnaap'
      request.headers['Accept'] = 'application/json'
    end
    json = JSON.parse(response.body)
    expect(json['issue'][2]['constituents']['uri']).not_to be_empty()
  end

  it "Returns a constituent as plain text" do
    response = springs.get do |request|
      request.url 'constituent/bmtnaap_1921-11_01/c003'
      request.headers['Accept'] = 'text/plain'
    end
    expect(response.body).to match(/too much selfhood in this lake/)
  end

  it "Returns a constituent as TEI" do
    response = springs.get do |request|
      request.url 'constituent/bmtnaap_1921-11_01/c003'
      request.headers['Accept'] = 'application/tei+xml'
    end
    xml = Nokogiri::XML(response.body)
    expect(xml.collect_namespaces['xmlns']).to eq("http://www.tei-c.org/ns/1.0")
  end

  it 'Returns status 400 if the supplied bmtnid does not correspond to a valid resource' do
    response = springs.get do |request|
      request.url 'constituent/bmtnaapzzz/c001'
    end
    expect(response.status).to eq(400)
  end

  it 'Returns status 202 if the supplied constituent does not correspond to a valid resource' do
    response = springs.get do |request|
      request.url 'constituent/bmtnaap_1921-11_01/cZZZ'
    end
    expect(response.status).to eq(400)
  end
end
