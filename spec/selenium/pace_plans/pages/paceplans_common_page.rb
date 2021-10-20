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

require_relative '../../common'

module PacePlansCommonPageObject
  def admin_setup
    feature_setup
    teacher_setup
    account_admin_user(:account => @account)
  end

  def create_assignment(course, assignment_title, description, points_possible, publish_status)
    course.assignments.create!(
      title: assignment_title,
      description: description,
      points_possible: points_possible,
      submission_types: 'online_text_entry',
      workflow_state: publish_status
    )
  end

  def create_course_module(module_title, workflow_state = 'active', assignment_publish_status = 'published')
    course_module = @course.context_modules.create!(:name => module_title, :workflow_state => workflow_state)
    module_assignment_title = "Module Assignment"
    assignment = create_assignment(@course, module_assignment_title, "Module Description", 10, assignment_publish_status)
    course_module.add_item(:id => assignment.id, :type => 'assignment')
    course_module
  end

  def create_dated_assignment(course, assignment_title, assignment_due_at, points_possible = 100)
    course.assignments.create!(
      title: assignment_title,
      grading_type: 'points',
      points_possible: points_possible,
      due_at: assignment_due_at,
      submission_types: 'online_text_entry'
    )
  end

  def feature_setup
    @account = Account.default
    @account.enable_feature!(:pace_plans)
  end

  def enable_pace_plans_in_course
    @course.update(enable_pace_plans: true)
  end

  def teacher_setup
    feature_setup
    @course_name = "Pace Plans Course"
    course_with_teacher(
      account: @account,
      active_course: 1,
      active_enrollment: 1,
      course_name: @course_name,
      name: 'PacePlan Teacher'
    )
  end
end
