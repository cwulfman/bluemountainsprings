require 'faraday'
require 'json'

springs = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/")

# exercise magazines spring
puts '+----- /magazines -----+'

puts '++----- /magazines as JSON -----++'
response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

JSON.parse(response.body)['magazine'].each do |m|
  puts m['primaryTitle']
end

puts '++----- /magazines as CSV -----++'
response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'text/csv'
end

puts response.body

# exercise magazines/bmtnid spring
puts '++----- /magazines/bmtnid as JSON -----++'
response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

JSON.parse(response.body)['magazine'].each do |m|

  puts m['primaryTitle']
  response = springs.get do |request|
    request.url  'magazines/' + m['bmtnid']
    request.headers['Accept'] = 'application/json'    
  end

  issues = JSON.parse(response.body)['issues']['issue']
  issues.each do |issue|
    puts issue
  end
  puts '------------------------------------------'
end

# exercise issues spring
puts '+----- /issues -----+'

puts '++----- /issues as json -----++'

spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/magazines/bmtnaap")

response = spring.get do |request|
  request.headers['Accept'] = 'application/json'
end

JSON.parse(response.body)['issues']['issue'].each do |issue|
  resp = spring.get do |request|
    request.url issue['url']
    request.headers['Accept'] = 'application/json'
  end
  puts resp.body
  puts '------------------------------------------'
end

puts '++----- /issues as TEI: single issue -----++'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/issues/bmtnaap_1921-11_01")
response = spring.get do |request|
  request.headers['Accept'] = 'application/tei+xml'
end

puts response.body


puts '++----- /issues as TEI: magazine -----++'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/issues/bmtnaad")
response = spring.get do |request|
  request.headers['Accept'] = 'application/tei+xml'
end

puts response.body

puts '++----- /issues as plain text -----++'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/issues/bmtnaap_1921-11_01")
response = spring.get do |request|
  request.headers['Accept'] = 'text/plain'
end

puts response.body

puts '++----- /issues as Collex-flavored RDF -----++'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/issues/bmtnaap_1921-11_01")
response = spring.get do |request|
  request.headers['Accept'] = 'application/rdf+xml'
end

puts response.body




# exercise constituents
puts '+----- /constituents -----+'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/issues/bmtnaai_1905-08_01")

response = spring.get do |request|
  request.headers['Accept'] = 'application/json'
end

puts '++----- TextContent -----++'
puts JSON.parse(response.body)['contributions']['TextContent']
puts '++----- Illustration -----++'
puts JSON.parse(response.body)['contributions']['Illustration']
puts '++----- SponsoredAdvertisement -----++'
puts JSON.parse(response.body)['contributions']['SponsoredAdvertisement']

puts '++----- TextContent itemized -----++'
puts '+++----- as plain text -----+++'
contents = JSON.parse(response.body)['contributions']['TextContent']
contents['contribution'].each do |c|
  spring = Faraday.new(url: c['uri'])
  response = spring.get do |request|
    request.headers['Accept'] = 'text/plain'
  end
  puts response.body
end

puts '+++----- as TEI -----+++'
contents['contribution'].each do |c|
  spring = Faraday.new(url: c['uri'])
  response = spring.get do |request|
    request.headers['Accept'] = 'application/tei+xml'
  end
  puts response.body
end

puts '+----- contributors/$bmtnid -----+'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/contributors/bmtnaap_1921-11_01")

puts '++----- contributors/$bmtnid as CSV -----++'
response = spring.get do |request|
  request.headers['Accept'] = 'text/csv'
end

puts response.body

puts '++----- contributors/$bmtnid as JSON -----++'
response = spring.get do |request|
  request.headers['Accept'] = 'application/json'
end

puts response.body


puts '+----- contributions -----+'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/contributions")

puts '++----- contributions as JSON -----++'
response = spring.get do |request|
  request.params['byline'] = 'Stevens'
  request.headers['Accept'] = 'application/json'
end

puts response.body

puts '++----- contributions as TEI -----++'
response = spring.get do |request|
  request.params['byline'] = 'Stevens'
  request.headers['Accept'] = 'application/tei+xml'
end

puts response.body
