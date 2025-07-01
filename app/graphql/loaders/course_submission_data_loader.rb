# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class Loaders::CourseSubmissionDataLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    super()
    @current_user = current_user
  end

  def perform(courses)
    unless @current_user
      courses.each { |course| fulfill(course, []) }
      return
    end

    submissions_by_course_id = @current_user.submissions
                                            .joins(:assignment)
                                            .merge(AbstractAssignment.published)
                                            .where(assignments: { context: courses, has_sub_assignments: false })
                                            .group_by(&:course_id)

    courses.each do |course|
      fulfill(course, submissions_by_course_id[course.id] || [])
    end
  end
end
