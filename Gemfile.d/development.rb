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
  gem "letter_opener", "~> 1.8"
  gem "spring-commands-parallel-rspec", "1.1.0"
  gem "spring-commands-rspec", "1.0.4"
  gem "spring-commands-rubocop", "~> 0.4"
  gem "active_record_query_trace", "~> 1.8", require: false

  gem "debug", "~> 1.8", platform: :mri, require: false
end
