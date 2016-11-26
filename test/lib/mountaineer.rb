require 'faraday'

class Mountaineer
  attr_accessor :url, :conn

  def initialize(url)
    @url = url.to_s
    @conn = Faraday.new(url: url) do |f|
      f.request :url_encoded
#      f.response :logger
      f.adapter Faraday.default_adapter
    end
  end

  def magazines(magid = nil)
    url = magid.nil? ? 'magazines' : 'magazines/' + magid
    response = @conn.get do |req|
      req.url url
      req.headers['Accept'] = 'application/json'
    end
    response.body    
  end

end
