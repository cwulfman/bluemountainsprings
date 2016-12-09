# Sample program showing how to use the
# Blue Mountain Springs API.
#
# Scenario: you want to retrieve all issues
# in English published between 1923 and 1924.

require 'date'
require 'faraday'
require 'json'

# Blue Mountain uses the w3cdtf format
# to represent dates, so precision varies:
# some dates are fully qualified YYYY-MM-DD,
# while others indicate only year and month
# (YYYY-MM) and others only the year (YYYY).
# A small utility function lets us use
# Ruby's date class for comparisons.

def bmtnDate(dateString)
  case
  when dateString.match(/^\d{4}-\d{2}-\d{2}$/)
    @date = Date.parse(dateString)
  when dateString.match(/^\d{4}-\d{2}$/)
    @date = Date.parse(dateString + "-01")
  when dateString.match(/^\d{4}$/)
    @date = Date.parse(dateString + "-01-01")
  else
    raise "bad date"
  end
end

# Specify the filter parameters: the bounding
# dates and the language.
startDate = bmtnDate('1923')
endDate = bmtnDate('1924')
language = 'eng'

# Use the Faraday client library to send a request
# to Blue Mountain Springs. Faraday has a rich syntax
# for communicating over HTTP; here we provide a
# base url for our request and then specify additional
# properties.
springs = Faraday.new(url: "http://localhost:8080/exist/restxq/springs/")
response = springs.get do |request|
  request.url 'magazines'
  request.headers['Accept'] = 'application/json'
end

# Parse the response body to extract the array of
# magazine objects.
magazines = JSON.parse(response.body)['magazine']

# Filter the magazines to include only those
# whose publication span covers our endpoints and
# whose primary language is English.
hits = magazines.select do |m|
  bmtnDate(m['startDate']) <= startDate and
    bmtnDate(m['endDate']) >= endDate and
    m['primaryLanguage']['ident'] == language
end

# Map over the filtered list of magazines to
# follow the 'issues' link in each magazine's
# representation and select the specific issues
# that fall within our range.
allIssues = hits.map do |magazine|
  issueSpring = Faraday.new(url: magazine['issues'])  
  issues = JSON.parse(issueSpring.get.body)['issues']['issue']
  issueSet = issues.select do |issue|
    bmtnDate(issue['date']) >= startDate and
      bmtnDate(issue['date']) <= endDate
  end
  issueSet
end

# You could continue to crawl the data set by iterating
# over each of the selected issues to extract individual
# constituents or the full text of the issue. Here we
# simply output the list of matching issues.

puts allIssues
