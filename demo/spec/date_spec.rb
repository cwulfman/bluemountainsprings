require 'Date'

RSpec.describe 'bmtnDate' do
  it "makes a proper date from YYYY-MM-DD" do
    input = "1898-03-01"
    check = Date.parse(input)
    date = BmtnDate.new(input)
    expect(date.date).to eql(check)
  end

  it "handles YYYY-MM" do
    input = "1898-03"
    date = BmtnDate.new(input)
    expect(date.date.to_s).to eq(input + "-01")
  end

  it "handles YYYY" do
    input = "1898"
    date = BmtnDate.new(input)
    expect(date.date.to_s).to eq(input + "-01-01")
  end

end
