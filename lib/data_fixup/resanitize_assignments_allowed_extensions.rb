#
# Copyright (C) 2013 - present Instructure, Inc.
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

module DataFixup::ResanitizeAssignmentsAllowedExtensions
  def self.run
    Assignment.where(["allowed_extensions IS NOT NULL AND updated_at > ?", "2013-03-08"]).find_each do |assignment|
      assignment.allowed_extensions = assignment.allowed_extensions
      Assignment.where(id: assignment).update_all(
        allowed_extensions: assignment.allowed_extensions
      )
    end
  end
end
