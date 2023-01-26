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

group :development do
  gem "letter_opener", "1.7.0"
  gem "spring", "4.0.0"
  gem "spring-commands-parallel-rspec", "1.1.0"
  gem "spring-commands-rspec", "1.0.4"
  gem "spring-commands-rubocop", "0.3.0", github: "rda1902/spring-commands-rubocop", ref: "818acb74130ac95adf9e8733986d45c168e4a5f3"
  gem "active_record_query_trace", "1.8", require: false

  gem "byebug", "11.1.3", platform: :mri
  # These gems aren't compatible with newer rubies; just use the built-in debug gem instead
  # Only try to install them if the env var is set so we don't have conditional gems in the
  # production build
  if ENV["REMOTE_DEBUGGING_ENABLED"]
    gem "debase", "0.2.5.beta2", require: false
    gem "ruby-debug-ide", "0.7.3", require: false
  end
end
