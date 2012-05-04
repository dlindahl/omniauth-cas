require 'bundler/setup'
require 'bourne'

RSpec.configure do |c|
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.mock_with :mocha
end

require 'simplecov'
SimpleCov.start

require 'rack/test'
# TODO: Remove this.
# https://github.com/bblimke/webmock/issues/64
# https://github.com/bblimke/webmock/commit/9d255f118a6a39d297856fa83302aca1577b2c03#commitcomment-192888
require 'rspec/expectations'
require 'webmock/rspec'
require 'omniauth-cas'
