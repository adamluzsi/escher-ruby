require 'rspec'
require 'escher'

fixtures = %w(
  get-header-key-duplicate
  get-header-value-order
  get-header-value-trim
  get-relative get-relative-relative
  get-slash
  get-slash-dot-slash
  get-slash-pointless-dot
  get-slashes
  get-space
  get-unreserved
  get-utf8
  get-vanilla
  get-vanilla-empty-query-key
  get-vanilla-query
  get-vanilla-query-order-key
  get-vanilla-query-order-key-case
  get-vanilla-query-order-value
  get-vanilla-query-unreserved
  get-vanilla-ut8-query
  post-header-key-case
  post-header-key-sort
  post-header-value-case
  post-vanilla
  post-vanilla-empty-query-value
  post-vanilla-query
  post-vanilla-query-space
  post-x-www-form-urlencoded
  post-x-www-form-urlencoded-parameters
)
# missing test:   post-vanilla-query-nonunreserved

describe 'Escher' do
  fixtures.each do |test|
    it "should calculate canonicalized request for #{test}" do
      method, url, body, date, headers = read_request(test)
      headers_to_sign = headers.map {|k| k[0].downcase }
      canonicalized_request = Escher.new.canonicalize method, url, body, date, headers, headers_to_sign
      check_canonicalized_request(canonicalized_request, test)
    end
  end

  fixtures.each do |test|
    it "should calculate string to sign for #{test}" do
      method, url, body, date, headers = read_request(test)
      headers_to_sign = headers.map {|k| k[0].downcase }
      canonicalized_request = Escher.new.canonicalize method, url, body, date, headers, headers_to_sign
      string_to_sign = Escher.new.get_string_to_sign 'us-east-1/host/aws4_request', canonicalized_request, date, 'SHA256', 'AWS4'
      expect(string_to_sign).to eq(fixture(test, 'sts'))    end
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
