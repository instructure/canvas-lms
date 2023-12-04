# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class AssignmentStudentVisibility < ActiveRecord::Base
  include VisibilityPluckingHelper

  belongs_to :user
  belongs_to :assignment, inverse_of: :assignment_student_visibilities, class_name: "AbstractAssignment"
  belongs_to :course

  # we are temporarily using a setting here because the feature flag
  # is not able to be directly checked when canvas boots
  def self.reset_table_name
    return super unless Setting.get("differentiated_modules_setting", "false") == "true"

    self.table_name = "assignment_student_visibilities_v2"
  end

  # create_or_update checks for !readonly? before persisting
  def readonly?
    true
  end

  def self.visible_assignment_ids_in_course_by_user(opts)
    visible_object_ids_in_course_by_user(:assignment_id, opts)
  end

  def self.assignments_with_user_visibilities(course, assignments)
    only_visible_to_overrides, visible_to_everyone = assignments.partition(&:only_visible_to_overrides)
    assignment_visibilities = {}

    if only_visible_to_overrides.any?
      options = { course_id: course.id, assignment_id: only_visible_to_overrides.map(&:id) }
      assignment_visibilities.merge!(users_with_visibility_by_assignment(options))
    end

    if visible_to_everyone.any?
      assignment_visibilities.merge!(
        assignments_visible_to_all_students(visible_to_everyone)
      )
    end
    assignment_visibilities
  end

  def self.assignments_visible_to_all_students(assignments_visible_to_everyone)
    assignments_visible_to_everyone.each_with_object({}) do |assignment, assignment_visibilities|
      # if an assignment is visible to everyone, we do not care about the contents
      # of its assignment_visibilities. instead of setting this to an array of every
      # student's ID, we set it to an empty array to save time when calling to_json
      assignment_visibilities[assignment.id] = []
    end
  end

  def self.users_with_visibility_by_assignment(opts)
    users_with_visibility_by_object_id(:assignment_id, opts)
  end

  def self.visible_assignment_ids_for_user(user_id, course_ids = nil)
    opts = { user_id: }
    if course_ids
      opts[:course_id] = course_ids
    end
    where(opts).pluck(:assignment_id)
  end

  # readonly? is not checked in destroy though
  before_destroy { raise ActiveRecord::ReadOnlyRecord }
end
