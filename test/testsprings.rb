require 'faraday'
require 'json'
require 'csv'
require 'logger'


springs_base = "http://localhost:8080/exist/restxq/springs/"

log = Logger.new(STDOUT)
springs = Faraday.new(url: springs_base)


# Exercise magazines/ spring

log.info '+ magazines'

log.info '++ magazines/ accepting application/json'
response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

log.info 'Got response'

JSON.parse(response.body)['magazine'].each do |m|
  log.debug  m['primaryTitle']
end


log.info '++ /magazines/bmtnid as JSON'
response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

JSON.parse(response.body)['magazine'].each do |m|

log.info '+++ ' + m['primaryTitle']
  response = springs.get do |request|
    request.url  'magazines/' + m['bmtnid']
    request.headers['Accept'] = 'application/json'    
  end

  issues = JSON.parse(response.body)['issues']['issue']
  issues.each do |issue|
    log.debug  issue
  end
end

# exercise issues spring
log.info '+ issues/'

log.info '++ issues/ as json'

response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

magazines = JSON.parse(response.body)['magazine']

magazines.each do |magazine|
  log.info 'retrieving ' + magazine['issues']
  conn = Faraday.new(url: magazine['issues'])

  response = conn.get do |request|
    request.headers['Accept'] = 'application/json'
  end

  issues = JSON.parse(response.body)['issues']['issue']
  if issues.kind_of?(Array)
    issues.each do |i|
      log.info i['id']
      conn = Faraday.new(url: i['url'])
      issue = conn.get do |request|
        request.headers['Accept'] = 'application/json'
      end
      log.info JSON.parse(issue.body)['bmtnid']
    end
  else
    log.info "singleton"
  end
end


log.info '++ issues/ as TEI'

response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

magazines = JSON.parse(response.body)['magazine']

magazines.each do |magazine|
  log.info 'retrieving ' + magazine['issues']
  conn = Faraday.new(url: magazine['issues'])

  response = conn.get do |request|
    request.headers['Accept'] = 'application/json'
  end

  issues = JSON.parse(response.body)['issues']['issue']
  if issues.kind_of?(Array)
    issues.each do |i|
      log.info i['id']
      conn = Faraday.new(url: i['url'])
      issue = conn.get do |request|
        request.headers['Accept'] = 'application/tei+xml'
      end
      log.info 'got it'
    end
  else
    log.info "singleton"
  end
end


log.info '++ issues/ as plain text'


response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

magazines = JSON.parse(response.body)['magazine']

magazines.each do |magazine|
  log.info 'retrieving ' + magazine['issues']
  conn = Faraday.new(url: magazine['issues'])

  response = conn.get do |request|
    request.headers['Accept'] = 'application/json'
  end

  issues = JSON.parse(response.body)['issues']['issue']
  if issues.kind_of?(Array)
    issues.each do |i|
      log.info i['id']
      conn = Faraday.new(url: i['url'])
      issue = conn.get do |request|
        request.headers['Accept'] = 'text/plain'
      end
      log.info 'got it'
    end
  else
    log.info "singleton"
  end
end


log.info '++ issues/ as rdf'


response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

magazines = JSON.parse(response.body)['magazine']

magazines.each do |magazine|
  log.info 'retrieving ' + magazine['issues']
  conn = Faraday.new(url: magazine['issues'])

  response = conn.get do |request|
    request.headers['Accept'] = 'application/json'
  end

  issues = JSON.parse(response.body)['issues']['issue']
  if issues.kind_of?(Array)
    issues.each do |i|
      log.info i['id']
      conn = Faraday.new(url: i['url'])
      issue = conn.get do |request|
        request.headers['Accept'] = 'application/rdf+xml'
      end
      log.info 'got it'
    end
  else
    log.info "singleton"
  end
end



# exercise constituents
log.info '+----- /constituents -----+'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/issues/bmtnaai_1905-08_01")

response = spring.get do |request|
  request.headers['Accept'] = 'application/json'
end

log.info '++----- TextContent -----++'
log.info JSON.parse(response.body)['contributions']['TextContent']
log.info '++----- Illustration -----++'
log.info JSON.parse(response.body)['contributions']['Illustration']
log.info '++----- SponsoredAdvertisement -----++'
log.info JSON.parse(response.body)['contributions']['SponsoredAdvertisement']

log.info '++----- TextContent itemized -----++'
log.info '+++----- as plain text -----+++'
contents = JSON.parse(response.body)['contributions']['TextContent']
contents['contribution'].each do |c|
  spring = Faraday.new(url: c['uri'])
  response = spring.get do |request|
    request.headers['Accept'] = 'text/plain'
  end
  log.debug response.body
end

log.info '+++----- as TEI -----+++'
contents['contribution'].each do |c|
  spring = Faraday.new(url: c['uri'])
  response = spring.get do |request|
    request.headers['Accept'] = 'application/tei+xml'
  end
  log.debug response.body
end

log.info '+----- contributors/$bmtnid -----+'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/contributors/bmtnaap_1921-11_01")

log.info '++----- contributors/$bmtnid as CSV -----++'
response = spring.get do |request|
  request.headers['Accept'] = 'text/csv'
end

log.debug response.body

log.info '++----- contributors/$bmtnid as JSON -----++'
response = spring.get do |request|
  request.headers['Accept'] = 'application/json'
end

log.debug response.body


log.info '+----- contributions -----+'
spring = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/contributions")

log.info '++----- contributions as JSON -----++'
response = spring.get do |request|
  request.params['byline'] = 'Stevens'
  request.headers['Accept'] = 'application/json'
end

log.debug response.body

log.info '++----- contributions as TEI -----++'
response = spring.get do |request|
  request.params['byline'] = 'Stevens'
  request.headers['Accept'] = 'application/tei+xml'
end

log.debug response.body
