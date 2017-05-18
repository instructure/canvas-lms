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
  if CANVAS_RAILS4_2
    gem 'rails-dom-testing', '1.0.8'
  else
    gem 'rails-dom-testing', '2.0.2'
    gem 'rails-controller-testing', '1.0.1'
  end

  gem 'gergich', '0.1.13', require: false
  gem 'dotenv', '2.2.1', require: false
  gem 'testingbot', require: false
  gem 'brakeman', require: false
  gem 'simplecov', '0.14.1', require: false, github: 'jenseng/simplecov', ref: '78c1171e98b7227f6bdd8f76f4c14666fd7fc5ea'
    gem 'docile', '1.1.5', require: false
  gem 'simplecov-rcov', '0.2.3', require: false
  gem 'mocha', github: 'maneframe/mocha', ref: 'bb8813fbb4cc589d7c58073d93983722d61b6919', require: false
    gem 'metaclass', '0.0.4', require: false
  gem 'puma', '3.8.2'

  gem 'rspec', '3.5.0'
  gem 'rspec_around_all', '0.2.0'
  gem 'rspec-rails', '3.5.2'
  gem 'rspec-collection_matchers', '1.1.3'
  gem 'shoulda-matchers', '3.1.1'

  gem 'rubocop-canvas', require: false, path: 'gems/rubocop-canvas'
    gem 'rubocop', '0.47.1', require: false
      gem 'rainbow', '2.2.1', require: false
  gem 'rubocop-rspec', '1.10.0', require: false

  gem 'once-ler', '0.1.1'

  # Keep this gem synced with docker-compose/seleniumff/Dockerfile
  gem 'selenium-webdriver', '2.53.4'
    gem 'childprocess', '0.5.9', require: false
    gem 'websocket', '1.2.3', require: false
  gem 'selinimum', '0.0.1', require: false, path: 'gems/selinimum'
  gem 'test_after_commit', '1.1.0' if CANVAS_RAILS4_2
  gem 'test-queue', github: 'jenseng/test-queue', ref: '1b92ebbca70705599c78a1bad5b16d6a37f741f2', require: false
  gem 'testrailtagging', '0.3.7', require: false

  gem 'webmock', '2.3.2', require: false
    gem 'crack', '0.4.3', require: false
  gem 'timecop', '0.8.1'
  gem 'jira_ref_parser', '1.0.1'
  gem 'headless', '2.3.1', require: false
  gem 'escape_code', '0.2', require: false
  gem 'hashdiff', '0.3.2'
end
