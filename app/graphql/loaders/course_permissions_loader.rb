#
# Copyright (C) 2018 - present Instructure, Inc.
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

# this is not a generally useful loader (it should be passed into the
# CoursePermissionType)
class Loaders::CoursePermissionsLoader < GraphQL::Batch::Loader
  def initialize(course, current_user:, session:)
    @course = course
    @current_user = current_user
    @session = session
  end

  def perform(permissions)
    rights = @course.rights_status(@current_user, @session, *permissions)
    rights.each { |right, perm| fulfill(right, perm) }
  end
end
