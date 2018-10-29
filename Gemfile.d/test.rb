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
  gem 'rails-controller-testing', '1.0.2'

  gem 'gergich', '0.2.2', require: false
  gem 'dotenv', '2.2.1', require: false
  gem 'testingbot', require: false
  gem 'brakeman', require: false
  gem 'simplecov', '0.15.1', require: false
    gem 'docile', '1.1.5', require: false
  gem 'simplecov-rcov', '0.2.3', require: false
  gem 'puma', '3.11.3'

  gem 'rspec', '3.7.0'
  gem 'rspec_around_all', '0.2.0'
  gem 'rspec-rails', '3.7.2'
  gem 'rspec-collection_matchers', '1.1.3'
  gem 'shoulda-matchers', '3.1.2'

  gem 'rubocop-canvas', require: false, path: 'gems/rubocop-canvas'
    gem 'rubocop', '0.52.1', require: false
      gem 'rainbow', '3.0.0', require: false
  gem 'rubocop-rspec', '1.22.2', require: false

  gem 'once-ler', '0.1.4'

  # Keep this gem synced with docker-compose/seleniumff/Dockerfile
  gem 'selenium-webdriver', '3.14.0'
    gem 'childprocess', '0.9.0', require: false
    gem 'websocket', '1.2.5', require: false
  gem 'chromedriver-helper', '2.1.0', require: false
  gem 'selinimum', '0.0.1', require: false, path: 'gems/selinimum'
  gem 'test-queue', github: 'instructure/test-queue', ref: 'd35166408df3a5396cd809e85dcba175136a69ba', require: false
  gem 'testrailtagging', '0.3.8.4', require: false

  gem 'webmock', '3.3.0', require: false
    gem 'crack', '0.4.3', require: false
  gem 'timecop', '0.9.1'
  gem 'jira_ref_parser', '1.0.1'
  gem 'headless', '2.3.1', require: false
  gem 'escape_code', '0.2', require: false
  gem 'hashdiff', '0.3.7'
  gem 'luminosity_contrast', '0.2.1'
  gem 'pact-support', github: 'tucker-m/pact-support', tag: 'pr1.2'
  gem 'pact', github: 'tucker-m/pact-ruby', tag: 'pr1.2'
  gem 'pact-messages', '0.2.0'
  gem 'pact_broker-client'
  gem 'database_cleaner', '~> 1.5', '>= 1.5.3'
end
