require 'spec_helper'
require 'faraday'
require 'json'
require 'nokogiri'

RSpec.describe 'issues' do
  let(:springs) { Faraday.new(:url => "http://localhost:8080/exist/restxq/springs/")  }
  
  it 'returns an issue as a TEI document' do
    response = springs.get do |request|
      request.url 'issues/bmtnaap_1921-11_01'
      request.headers['Accept'] = 'application/tei+xml'
    end
    xml = Nokogiri::XML(response.body)
    expect(xml.collect_namespaces['xmlns']).to eq("http://www.tei-c.org/ns/1.0")
  end

  it 'returns an issue as an RDF document' do
    response = springs.get do |request|
      request.url 'issues/bmtnaap_1921-11_01'
      request.headers['Accept'] = 'application/rdf+xml'
    end
    xml = Nokogiri::XML(response.body)
    expect(xml.collect_namespaces['xmlns:rdf']).to eq("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
  end

  it 'returns an issue as JSON' do
    response = springs.get do |request|
      request.url 'issues/bmtnaap_1921-11_01'
      request.headers['Accept'] = 'application/json'
    end
    json = JSON.parse(response.body)
    expect(json['bmtnid']).to eq('bmtnaap_1921-11_01')
  end

  it 'returns an issue as plain text' do
    response = springs.get do |request|
      request.url 'issues/bmtnaap_1921-11_01'
      request.headers['Accept'] = 'text/plain'
    end
    expect(response.body).not_to be_empty()
  end

  it 'returns a magazine as TEI' do
    response = springs.get do |request|
      request.url 'issues/bmtnaad'
      request.headers['Accept'] = 'application/tei+xml'
    end
    xml = Nokogiri::XML(response.body)
    expect(xml.collect_namespaces['xmlns']).to eq("http://www.tei-c.org/ns/1.0")
  end

  it 'returns a magazine as an RDF document' do
    response = springs.get do |request|
      request.url 'issues/bmtnaad'
      request.headers['Accept'] = 'application/rdf+xml'
    end
    xml = Nokogiri::XML(response.body)
    expect(xml.collect_namespaces['xmlns:rdf']).to eq("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
  end


  it 'returns a magazine as JSON' do
    response = springs.get do |request|
      request.url 'issues/bmtnaad'
      request.headers['Accept'] = 'application/json'
    end
    json = JSON.parse(response.body)
    expect(json['bmtnid']).to eq('bmtnaad')
  end

  it 'returns a magazine as plain text' do
    response = springs.get do |request|
      request.url 'issues/bmtnaad'
      request.headers['Accept'] = 'text/plain'
    end
    expect(response.body).not_to be_empty()
  end

  it 'returns status 400 if the supplied bmtnid does not represent a valid resource' do
    response = springs.get do |request|
      request.url 'issues/bmtnaZZZZ'
    end
    expect(response.status).to eq(400)
  end
end
