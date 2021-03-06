# frozen_string_literal: true

require "bundler/setup"
require "dbdoc"
require "byebug"
require_relative "helpers/with_dbdoc_folder"

if ENV["TRAVIS"]
  require "coveralls"
  Coveralls.wear!
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Helpers
end
