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
  gem "rails-controller-testing", "1.0.5"

  gem "dotenv", "~> 3.0", require: false
  gem "brakeman", "~> 6.0", require: false
  gem "simplecov-rcov", "~> 0.3", require: false
  gem "puma", "~> 6.3", require: false

  gem "db-query-matchers", "~> 0.12"
  gem "rspec", "~> 3.12"
  gem "rspec_around_all", "0.2.0"
  gem "rspec-rails", "~> 6.0"
  gem "rspec-collection_matchers", "~> 1.2"
  gem "shoulda-matchers", "~> 6.0"

  gem "once-ler", "~> 2.0"

  gem "rspec-openapi"
  gem "selenium-webdriver", "~> 4.12", require: false
  gem "testrailtagging", "0.3.8.7", require: false

  gem "webmock", "~> 3.18", require: false
  gem "timecop", "~> 0.9"
  gem "headless", "2.3.1", require: false
  gem "escape_code", "0.2", require: false
  gem "luminosity_contrast", "0.2.1"
  gem "pact", "~> 1.57", require: false
    # needed so that bundler-multilock will allow us to use the Rack 3 compatible version with Rails 7.1, without complaining about version mismatches
    gem "pact-mock_service", ($canvas_rails == "7.1") ? ">= 3.12" : "3.11.2"
  gem "pact-messages", "0.2.0"
  # pinned to 1.72 due to contract tests breaking with the following versions
  gem "pact_broker-client", "1.72"
  gem "database_cleaner", "~> 2.0"
  gem "json-schema", "~> 4.0"

  gem "rspecq", github: "instructure/rspecq"
  gem "flakey_spec_catcher", "~> 0.12", require: false
  gem "factory_bot", "~> 6.3", require: false
  gem "stormbreaker", "~> 1.0", require: false

  # performance tools for instrumenting rspec tests
  gem "stackprof", "~> 0.2"

  gem "crystalball", github: "wrapbook/crystalball", require: false
end
