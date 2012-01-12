require 'bundler/setup'

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

require 'simplecov'
SimpleCov.start

require 'rack/test'
require 'webmock/rspec'
require 'omniauth-cas'
