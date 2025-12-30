# frozen_string_literal: true

require 'nfcom'
require 'webmock/rspec'
require 'vcr'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before(:each) do
    Nfcom.reset_configuration!
  end
end

# VCR configuration for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter sensitive data
  config.filter_sensitive_data('<CERTIFICADO>') { |interaction| 
    # Hide certificate data from recordings
    interaction.request.headers['Authorization']&.first
  }
  
  config.filter_sensitive_data('<CSC>') do
    ENV['NFCOM_CSC'] || 'fake_csc'
  end
end
