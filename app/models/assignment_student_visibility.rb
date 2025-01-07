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

  # create_or_update checks for !readonly? before persisting
  def readonly?
    true
  end

  # TODO: what to do here?
  def self.where_with_guard(*)
    raise StandardError, "AssignmentStudentVisibility view should not be used.  Use AssignmentVisibilityService instead"
  end

  class << self
    alias_method :where_without_guard, :where
    alias_method :where, :where_with_guard
  end

  def self.visible_assignment_ids_in_course_by_user(opts) # rubocop:disable Lint/UnusedMethodArgument
    raise StandardError, "AssignmentStudentVisibility view should not be used.  Use AssignmentVisibilityService instead"
  end

  def self.assignments_with_user_visibilities(course, assignments) # rubocop:disable Lint/UnusedMethodArgument
    raise StandardError, "AssignmentStudentVisibility view should not be used.  Use AssignmentVisibilityService instead"
  end

  def self.users_with_visibility_by_assignment(opts) # rubocop:disable Lint/UnusedMethodArgument
    raise StandardError, "AssignmentStudentVisibility view should not be used.  Use AssignmentVisibilityService instead"
  end

  def self.visible_assignment_ids_for_user(user_id, course_ids = nil) # rubocop:disable Lint/UnusedMethodArgument
    raise StandardError, "AssignmentStudentVisibility view should not be used.  Use AssignmentVisibilityService instead"
  end

  # readonly? is not checked in destroy though
  before_destroy { raise ActiveRecord::ReadOnlyRecord }
end
