# frozen_string_literal: true

require "page_frames"
require 'yaml'
require 'active_support/core_ext/hash/indifferent_access'
require 'bunny-mock'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    PageFrames::RabbitMq.connection = BunnyMock.new.start
  end

  config.before do
    PageFrames.configure do |c|
      c.model_pages = YAML.load_file("spec/fixtures/pages.yml").with_indifferent_access
      c.validators = YAML.load_file("spec/fixtures/validators.yml").with_indifferent_access
    end
  end
end
