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

class Loaders::CourseRoleLoader < GraphQL::Batch::Loader
  def initialize(course_id:, role_types: nil, built_in_only: false)
    @course_id = course_id
    @role_types = role_types
    @built_in_only = built_in_only
  end

  def perform(objects)
    scope = Enrollment
            .joins(:course)
            .where.not(enrollments: { workflow_state: "deleted" })
            .where.not(courses: { workflow_state: "deleted" })
            .where(course_id: @course_id)
            .where(user_id: objects)
            .select(:type, :user_id)
            .distinct

    scope = scope.where(type: @role_types) if @role_types.present?

    scope = scope.joins(:role).where(roles: { workflow_state: "built_in" }) if @built_in_only

    enrollments = scope.group_by(&:user_id)

    objects.each do |object|
      fulfill(object, enrollments[object.id]&.map(&:type))
    end
  end
end
