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
RSpec::Matchers.define :encompass do |expected|
  match do |actual|
    if expected.is_a?(Array) && actual.is_a?(Array)
      expected.size == actual.size && expected.zip(actual).all? { |e, a| a.slice(*e.keys) == e }
    elsif expected.is_a?(Hash) && actual.is_a?(Hash)
      actual.slice(*expected.keys) == expected
    else
      false
    end
  end
end
