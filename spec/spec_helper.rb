require 'rubygems'
require 'bundler'
require 'sinatra'
require 'hub/samples'

Bundler.require(:default, :test)

require 'simplecov'
SimpleCov.start

require File.join(File.dirname(__FILE__), '..', 'square_endpoint.rb')

Dir['./spec/support/**/*.rb'].each &method(:require)

Sinatra::Base.environment = 'test'

def app
  SquareEndpoint
end

def testing_credentials
  YAML.load_file("spec/square_testing.yml").with_indifferent_access
end

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock

  %w[
    square_merchant_id
    square_token
  ].each do |field|
    c.filter_sensitive_data(field) {|_| testing_credentials[field] }
  end

  c.filter_sensitive_data("AUTHORIZATION") do |interaction|
    interaction.request.headers['Authorization'][0]
  end
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.include Rack::Test::Methods
  config.order = 'random'
end

def app
  SquareEndpoint
end

def json_response
  JSON.parse(last_response.body)
end
