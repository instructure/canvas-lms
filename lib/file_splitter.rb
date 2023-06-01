# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# Used inside the parsers to either parse by comma or parse by line.
module FileSplitter
  # OK, lame, but if there's a commas, call it comma-seperated
  def format
    @format = @txt.include?(",") ? :each_record : :each_line
  end

  # Send it a block, expects @txt to be set in the parser.
  def each_entry(&)
    send(format, &)
  end

  def each_line(&)
    @txt.each_line(&)
  end

  # Comma-seperated list, all one list
  def each_record(&)
    @txt.split(",").each(&)
  end
end
