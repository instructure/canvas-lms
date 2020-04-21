#
# Copyright (C) 2020 - present Instructure, Inc.
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
module EventStream::Backend
  # this is supposed to be a bit like an interface.
  # Backend classes that include this module should know
  # what methods they're expected to provide an implementation for.
  # See the cassandra.rb and active_record.rb fils in this directory for
  # examples
  module Strategy
    def available?
      raise "Not Implemented"
    end

    def execute(_operation, _record)
      raise "Not Implemented"
    end
  end
end