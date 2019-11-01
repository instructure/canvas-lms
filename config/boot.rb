# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

# TODO: remove me. Still trying to figure out what's going on in heroku!
pp "Running boot.rb! LOGGER_TYPE=#{ENV['LOGGER_TYPE']}"
