# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CustomColorHelper
  HEX_REGEX = /^#?(\h{3}|\h{6})$/

  # returns true or false if the provide value is a valid hex code
  def valid_hexcode?(hex_to_check)
    # Early escape if nil was passed in
    return false if hex_to_check.nil?

    # Check the hex to see if it matches our regex
    value = HEX_REGEX =~ hex_to_check
    # If there wasn't a match it returns null, so return the reverse of a null check
    !value.nil?
  end

  def normalize_hexcode(hex_to_normalize)
    if hex_to_normalize.start_with?("#")
      hex_to_normalize
    else
      "#" + hex_to_normalize
    end
  end
end
