# Exercise Blue Mountain Springs by walking the tree of
# magazines and issues and accessing each constituent.
require 'faraday'
require 'json'
require 'csv'
require 'logger'


log = Logger.new(STDOUT)

springs_base = "http://localhost:8080/exist/restxq/springs/"
springs = Faraday.new(url: springs_base)

request = "magazines"
log.info "sending request #{request}"
response = springs.get do |r|
  r.url request
  r.headers['Accept'] = 'application/json'
end

unless response.status == 200
  log.warn "unexpected status: #{response.status}"
end

magazines = JSON.parse(response.body)['magazine']
log.info "found #{magazines.count} magazines"

# iterate over the magazine objects
log.info "examining magazines"
magazines.each do |m|
  log.info "examining #{m['bmtnid']}"
  issuelink = m['issues']
  unless issuelink
    log.warn "#{m['bmtnid']} has no issue link"
  end
  spring = Faraday.new(url: issuelink)
  response = spring.get do |request|
    request.headers['Accept'] = 'application/json'
  end

  unless response.status == 200
    log.warn "unexpected status: #{response.status}"
  end

  issues = JSON.parse(response.body)['issues']
  # have to get around known issue with parsing JSON: plural
  # values are returned in an array but singletons are not.
  # must check to see if there is only one issue by testing
  # the kind of thing the issue is. Bleh.

  if issues['issue'].kind_of?(Array) then
    log.info "found #{issues['issue'].count} issues"
    urls = issues['issue'].collect { |i| i['url']  }
  else
    log.info "found single issue"
    urls = Array(issues['issue']['url'])
  end

  log.info "examining #{urls.count} issue(s)"
  urls.each do |url|
    spring = Faraday.new(url: url)
    response = spring.get do |request|
      request.headers['Accept'] = 'application/json'
    end
    
    unless response.status == 200
      log.warn "unexpected status: #{response.status}"
    end

    issue = JSON.parse(response.body)

    log.info "issue id: #{issue['bmtnid']}"
    
    ['TextContent', 'Illustration', 'SponsoredAdvertisement'].each do |contentType|
      if issue['contributions'][contentType]
      then
        if issue['contributions'][contentType]['contribution'].kind_of?(Array) then
          log.info "#{issue['contributions'][contentType]['contribution'].count} #{contentType} contributions"
          contributions = issue['contributions'][contentType]['contribution']
          log.info "examining #{contentType} contributions"
          contributions.each do |c|
            uri = c['uri']
            spring = Faraday.new(url: uri)
            response = spring.get do |request|
              request.headers['Accept'] = 'application/tei+xml'
            end
            unless response.status == 200
              log.warn "no TEI: #{uri}"
            end
            response = spring.get do |request|
              request.headers['Accept'] = 'text/plain'
            end
            unless response.status == 200
              log.warn "no plain text: #{uri}"
            end
            

          end
        else

          contribution = issue['contributions'][contentType]['contribution']
          log.debug contribution['uri']
        end
      else
        log.info "issue contains no #{contentType}"
      end
    end
  end
end
