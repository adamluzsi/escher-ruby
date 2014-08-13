require 'rspec'
require 'escher'

fixtures = %w(get-vanilla-query post-x-www-form-urlencoded get-header-key-duplicate)

describe 'Escher' do
  fixtures.each do |test|
    it "should calculate canonicalized request for #{test}" do
        method, url, body, date, headers = read_request(test)
        headers_to_sign = headers.map {|k| k[0].downcase }
        canonicalized_request = Escher.new.canonicalize method, url, body, date, headers, headers_to_sign
        check_canonicalized_request(canonicalized_request, test)
    end
  end
end

def fixture(test, extension)
  open('spec/aws4_testsuite/'+test+'.'+extension).read
end

def get_host(headers)
  headers.detect {|header| k, v = header; k.downcase == 'host'}[1]
end

def get_date(headers)
  headers.detect {|header| k, v = header; k.downcase == 'date'}[1]
end

def read_request(test)
  lines = (fixture(test, 'req') + "\n").lines.map(&:chomp)
  method, uri = lines[0].split ' '
  headers = lines[1..-3].map { |header| k, v = header.split(':', 2); [k, v] }
  url = 'http://'+ get_host(headers) + uri

  body = lines[-1]
  date = get_date(headers)
  return method, url, body, date, headers
end

def check_canonicalized_request(canonicalized_request, test)
  expect(canonicalized_request).to eq(fixture(test, 'creq'))
end
