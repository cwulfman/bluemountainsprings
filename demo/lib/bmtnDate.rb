require 'Date'
class BmtnDate
  attr_reader :date

  def initialize(dateString)
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
end
