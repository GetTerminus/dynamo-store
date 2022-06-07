# frozen_string_literal: true

require 'bundler/setup'
require 'dynamo-store/version'
require 'timecop'
require 'deep_cover/builtin_takeover'
require 'simplecov'

SimpleCov.start do
  add_filter '/vendor/'
  add_filter '/spec/'

  if ENV['CI']
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter
  end
end

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
