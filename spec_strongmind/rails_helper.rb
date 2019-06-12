# This file is copied to spec/ when you run 'rails generate rspec:install'

require 'dotenv'
Dotenv.load('.env.test')

ENV['RAILS_ENV'] ||= 'test'
ENV['STRONGMIND_SPEC'] = 'true'

require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require_relative 'spec_helper'

require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'factory_bot_rails'
require 'vcr'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'shoulda/matchers'
require 'rake'
require 'capybara-screenshot/rspec'
require 'delayed/testing' # inst-jobs testing

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#

Dir[Rails.root.join('spec', 'factories', '*.rb')].each { |f| require f }
Dir[Rails.root.join('spec_strongmind/support/helpers/common_helper_methods/*.rb')].each { |f| require f }
require Rails.root.join('spec/support/discourage_slow_specs.rb')
require Rails.root.join('spec/selenium/test_setup/custom_selenium_rspec_matchers')

module SeleniumDependencies
  # Why are these modules commented out here? Because there is Canvas testing gold in these files
  # but they need slight tweaks to work with Capbyara instead of Selenium Webdriver directly.
  # The intent here is to put them more in your face, you may not know they exists or can be
  # leverage for making canvas testing easier.  CI

  # include OtherHelperMethods
  # include CustomSeleniumActions
  # include CustomAlertActions
  # include CustomScreenActions
  # include CustomValidators
  # include CustomWaitMethods
  # include CustomDateHelpers
  include LoginAndSessionMethods
  # include CustomPageLoaders
  # include SeleniumErrorRecovery
end

# Load spec helper modules first
Dir[Rails.root.join('spec_strongmind', 'support', 'helpers', '**', '*.rb')].each { |f| require f }
# Then the rest
Dir[Rails.root.join('spec_strongmind', 'support', '**', '*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# ActiveRecord::Migration.maintain_test_schema!
