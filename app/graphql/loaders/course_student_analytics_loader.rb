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

# This is a dummy implementation. The real implementation is provided by the
# Canvas analytics plugin
class Loaders::CourseStudentAnalyticsLoader < GraphQL::Batch::Loader
  def initialize(course_id, current_user:, session:)
    @course_id = course_id
    @current_user = current_user
    @session = session
  end

  def perform(users)
    users.each { |u| fulfill(u, nil) }
  end
end

