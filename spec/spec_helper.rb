# frozen_string_literal: true

require 'bundler/setup'
require 'dynamo-store/version'
require 'timecop'
require 'deep_cover/builtin_takeover'
require 'simplecov'
SimpleCov.start

ENV['DYNAMODB_ENDPOINT'] ||= 'http://localhost:8000'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each) do |e|
    Timecop.freeze do
      e.run
    end
  end
end
