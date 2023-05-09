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
  gem "gergich", "2.1.1", require: false
    gem "mime-types-data", "~> 3.2023", require: false

  rubocop_canvas_path = "gems/rubocop-canvas"
  if File.dirname(@gemfile) == __dir__
    rubocop_canvas_path = "../#{rubocop_canvas_path}"
  end

  gem "rubocop-canvas", require: false, path: rubocop_canvas_path
  gem "rubocop-inst", "~> 1", require: false
  gem "rubocop-graphql", "1.1.1", require: false
  gem "rubocop-rails", "2.19.1", require: false
  gem "rubocop-rake", "0.6.0", require: false
  gem "rubocop-rspec", "2.19.0", require: false
end
