# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

group :test do
  gem 'rails-dom-testing', '2.0.3'
  gem 'rails-controller-testing', '1.0.5'

  gem 'gergich', '1.2.1', require: false
  gem 'dotenv', '2.7.5', require: false
  gem 'testingbot', require: false
  gem 'brakeman', require: false
  gem 'simplecov', '0.15.1', require: false
    gem 'docile', '1.1.5', require: false
  gem 'simplecov-rcov', '0.2.3', require: false
  gem 'puma', '5.2.2', require: false

  gem 'db-query-matchers', '0.10.0'
  gem 'rspec', '3.9.0'
  gem 'rspec_around_all', '0.2.0'
  gem 'rspec-rails', '4.0.1'
  gem 'rspec-collection_matchers', '1.2.0'
  gem 'rspec-support', '3.9.2'
  gem 'rspec-expectations', '3.9.0'
  gem 'rspec-mocks', '3.9.1'
  gem 'shoulda-matchers', '4.3.0'

  gem 'rubocop-canvas', require: false, path: 'gems/rubocop-canvas'
    gem 'rubocop', '0.68.0', require: false
      gem 'rainbow', '3.0.0', require: false
  gem 'rubocop-rspec', '1.33.0', require: false
  gem 'rubocop-performance', '1.3.0', require: false

  gem 'once-ler', '0.1.4'
  gem 'sauce_whisk', '0.2.2'

  gem 'selenium-webdriver', '3.142.7', require: false
    gem 'childprocess', '3.0.0', require: false
  gem 'webdrivers', '4.2.0', require: false
  gem 'test-queue', github: 'instructure/test-queue', ref: 'd35166408df3a5396cd809e85dcba175136a69ba', require: false
  gem 'testrailtagging', '0.3.8.7', require: false

  gem 'webmock', '3.8.2', require: false
    gem 'crack', '0.4.3', require: false
  gem 'timecop', '0.9.1'
  gem 'jira_ref_parser', '1.0.1'
  gem 'headless', '2.3.1', require: false
  gem 'escape_code', '0.2', require: false
  gem 'luminosity_contrast', '0.2.1'
  gem 'pact', '1.49.0', require: false
    gem 'pact-mock_service', '3.5.0', require: false
    gem 'pact-support', '1.15.1', require: false # pinned until https://github.com/pact-foundation/pact-support/issues/81 fixed
  gem 'pact-messages', '0.2.0'
  gem 'pact_broker-client', '1.25.0'
  gem 'database_cleaner', '~> 1.5', '>= 1.5.3'

  gem 'parallel_tests'
  gem 'flakey_spec_catcher', require: false
  gem 'factory_bot', '6.1.0', require: false
  gem 'rspec_junit_formatter', require: false
  gem 'axe-core-selenium', '4.1.0', require: false
  gem 'axe-core-rspec', '4.1.0', require: false
end
