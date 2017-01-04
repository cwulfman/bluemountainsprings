require 'faraday'
require 'json'
require 'csv'
require 'logger'


springs_base = "http://bluemountain.princeton.edu/exist/restxq/springs/"

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
