require 'spec_helper'
require 'faraday'
require 'json'
require 'nokogiri'
require 'csv'

RSpec.describe 'contributors' do
  let(:springs) { Faraday.new(:url => "http://localhost:8080/exist/restxq/springs/")  }

  it "Returns a list of issue contributors as CSV" do
    response = springs.get do |request|
      request.url 'contributors/bmtnaap_1921-11_01'
      request.headers['Accept'] = 'text/csv'
    end
    expect(response.body).not_to be_empty()
    expect(CSV.parse(response.body)[1][2]).to eq('http://viaf.org/viaf/19762459')
  end

  it "Returns a list of magazine contributors as CSV" do
    response = springs.get do |request|
      request.url 'contributors/bmtnaap'
      request.headers['Accept'] = 'text/csv'
    end
    expect(response.body).not_to be_empty()
  end

  it "Returns a list of issue contributors as JSON" do
    response = springs.get do |request|
      request.url 'contributors/bmtnaap_1921-11_01'
      request.headers['Accept'] = 'application/json'
    end
    expect(JSON.parse(response.body)['contributor'].first['contributorid']).to eq('http://viaf.org/viaf/19762459')
  end

  it "Returns a list of magazine contributors as JSON" do
    response = springs.get do |request|
      request.url 'contributors/bmtnaap'
      request.headers['Accept'] = 'application/json'
    end
    expect(response.body).not_to be_empty()
  end
end
