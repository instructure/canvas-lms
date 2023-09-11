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

# these gems are separate from test.rb so that we can treat it as a dedicated
# Gemfile for script/rlint, and it will run very quickly.

source "https://rubygems.org/"

group :test do
  gem "colorize", "~> 1.0", require: false
  gem "gergich", "~> 2.1", require: false

  gem "rubocop-canvas", require: false, path: "../gems/rubocop-canvas"
  gem "rubocop-inst", "~> 1", require: false
  gem "rubocop-graphql", "~> 1.3", require: false
  gem "rubocop-rails", "~> 2.19", require: false
  gem "rubocop-rake", "~> 0.6", require: false
  gem "rubocop-rspec", "~> 2.22", require: false
end
