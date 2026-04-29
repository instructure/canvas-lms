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

class Loaders::CourseModuleProgressionDataLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    super()
    @current_user = current_user
  end

  def perform(courses)
    unless @current_user
      courses.each { |course| fulfill(course, []) }
      return
    end

    progressions_by_course_id = @current_user.context_module_progressions
                                             .joins(:context_module)
                                             .preload(:context_module)
                                             .where(context_modules: { context_type: "Course", context_id: courses })
                                             .where("context_module_progressions.current = ? OR context_module_progressions.evaluated_at IS NOT NULL", true)
                                             .group_by { |p| p.context_module.context_id }

    courses.each do |course|
      fulfill(course, progressions_by_course_id[course.id] || [])
    end
  end
end
