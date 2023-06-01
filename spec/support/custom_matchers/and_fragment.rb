# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
#
RSpec::Matchers.define :and_fragment do |expected|
  match do |actual|
    fragment = JSON.parse(URI.decode_www_form_component(URI(actual).fragment))
    expected_as_strings = RSpec::Matchers::Helpers.cast_to_strings(expected:)
    values_match?(expected_as_strings, fragment)
  end
end
