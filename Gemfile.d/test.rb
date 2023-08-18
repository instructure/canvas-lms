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
  gem "rails-dom-testing", "~> 2.1"
  gem "rails-controller-testing", "1.0.5"

  gem "dotenv", "~> 2.8", require: false
  gem "brakeman", "~> 6.0", require: false
  gem "simplecov", "~> 0.22", require: false
  gem "simplecov-rcov", "~> 0.3", require: false
  gem "puma", "~> 6.3", require: false

  gem "db-query-matchers", "0.11.0"
  gem "rspec", "~> 3.12"
  gem "rspec_around_all", "0.2.0"
  gem "rspec-rails", "~> 6.0"
  gem "rspec-collection_matchers", "1.2.0"
  gem "shoulda-matchers", "~> 5.3"

  gem "once-ler", "2.0.1"
  gem "sauce_whisk", "~> 0.3"

  gem "selenium-webdriver", "~> 4.11.0", require: false
  gem "testrailtagging", "0.3.8.7", require: false

  gem "webmock", "~> 3.18", require: false
  gem "timecop", "~> 0.9"
  gem "jira_ref_parser", "1.0.1"
  gem "headless", "2.3.1", require: false
  gem "escape_code", "0.2", require: false
  gem "luminosity_contrast", "0.2.1"
  gem "pact", "~> 1.57", require: false
  gem "pact-messages", "0.2.0"
  gem "pact_broker-client", "~> 1.66"
  gem "database_cleaner", "~> 2.0"
  gem "json-schema", "~> 4.0"

  gem "rspecq", github: "kyler-instructure/rspecq", ref: "8cea6a3225cf0856a26c6c6b93a5ea5605082aa0"
  gem "flakey_spec_catcher", "~> 0.12", require: false
  gem "factory_bot", "6.2.1", require: false
  gem "rspec_junit_formatter", require: false
  gem "stormbreaker", "~> 1.0", require: false

  # performance tools for instrumenting rspec tests
  gem "stackprof", "~> 0.2"

  gem "crystalball", github: "wrapbook/crystalball", require: false
end
