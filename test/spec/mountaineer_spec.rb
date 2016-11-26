require 'spec_helper'
require 'uri'
require 'json'

RSpec.describe Mountaineer do
  let(:springs_root) { "http://localhost:8080/exist/restxq/springs/" }
  let(:neer) { Mountaineer.new(springs_root) }
  
  it 'has a url' do
    expect(neer.url).to eq(springs_root)
    expect(neer.conn.url_prefix.host).to eq('localhost')
  end

  it 'has a connection' do
    expect(neer.conn.url_prefix.host).to eq('localhost')
    expect(neer.conn.url_prefix.path).to eq('/exist/restxq/springs/')
  end

  it 'retrieves magazines' do
    expect(neer.magazines).not_to be_empty()
  end

  it 'retrieves Broom' do
    broom = JSON.parse(neer.magazines('bmtnaap'))
    expect(broom['bmtnid']).to eq('bmtnaap')
  end
end
