#
# Copyright (C) 2011-2014 Instructure, Inc.
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

require "uuid"

# Creating a testable Singleton for UUID
class CanvasUUID < ::UUID
  def self.instance
    @@uuid_singleton ||= new
  end

  def self.generate
    instance.generate
  end
end

# Disable the UUID lib's state file thing. Across all processes, defaults to 
# /var/tmp/ruby-uuid? *boggle*. We could do a tempfile thing, but this lib
# doesn't clean up after itself.
CanvasUUID.state_file = false
