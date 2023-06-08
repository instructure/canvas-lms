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

require_relative "../../common"
require_relative "../../helpers/color_common"

module K5DashboardCommonPageObject
  include ColorCommon

  def add_and_assess_rubric_assignment
    rubric = outcome_with_rubric(course: @subject_course)
    assignment = create_assignment(@course, "Rubric Assignment", "Description of Rubric", 10)
    association = rubric.associate_with(assignment, @subject_course, purpose: "grading", use_for_grading: true)
    submission = assignment.submit_homework(@student, { submission_type: "online_text_entry", body: "Here it is" })
    association.assess(
      user: @student,
      assessor: @teacher,
      artifact: submission,
      assessment: {
        assessment_type: "grading",
        "criterion_#{@rubric.criteria_object.first.id}": {
          points: 3,
          comments: "a comment",
        }
      }
    )
    assignment
  end

  def admin_setup
    feature_setup
    teacher_setup
    account_admin_user(account: @account)
  end

  def create_and_submit_assignment(course, assignment_title, description, points_possible)
    assignment = create_assignment(course, assignment_title, description, points_possible)
    assignment.submit_homework(@student, { submission_type: "online_text_entry", body: "Here it is" })
    assignment
  end

  def create_assignment(course, assignment_title, description, points_possible)
    course.assignments.create!(
      title: assignment_title,
      description:,
      points_possible:,
      submission_types: "online_text_entry",
      workflow_state: "published"
    )
  end

  def create_calendar_event(course, calendar_event_title, start_at)
    course.calendar_events.create!(title: calendar_event_title, start_at:)
  end

  def create_course_module(workflow_state = "active")
    @module_title = "Course Module"
    @course_module = @subject_course.context_modules.create!(name: @module_title, workflow_state:)
    @module_assignment_title = "General Assignment"
    assignment = create_dated_assignment(@subject_course, @module_assignment_title, 1.day.from_now)
    @course_module.add_item(id: assignment.id, type: "assignment")
  end

  def create_dated_assignment(course, assignment_title, assignment_due_at, points_possible = 100)
    course.assignments.create!(
      title: assignment_title,
      grading_type: "points",
      points_possible:,
      due_at: assignment_due_at,
      submission_types: "online_text_entry"
    )
  end

  def create_grading_standard(course)
    course.grading_standards.create!(
      title: "Fun Grading Standard",
      standard_data: {
        "scheme_0" => { name: "Awesome", value: "90" },
        "scheme_1" => { name: "Fabulous", value: "80" },
        "scheme_2" => { name: "You got this", value: "70" },
        "scheme_3" => { name: "See me", value: "0" }
      }
    )
  end

  def create_important_info_content(course, info_text)
    course.syllabus_body = "<p>#{info_text}</p>"
    course.save!
  end

  def create_lti_resource(resource_name)
    rendered_icon = "https://lor.instructure.com/img/icon_commons.png"
    lti_resource_url = "http://www.example.com"
    tool =
      Account.default.context_external_tools.new(
        {
          name: resource_name,
          domain: "canvaslms.com",
          consumer_key: "12345",
          shared_secret: "secret",
          is_rce_favorite: "true"
        }
      )
    tool.set_extension_setting(
      :editor_button,
      {
        message_type: "ContentItemSelectionRequest",
        url: lti_resource_url,
        icon_url: rendered_icon,
        text: "#{resource_name} Favorites",
        enabled: "true",
        use_tray: "true",
        favorite: "true"
      }
    )
    tool.course_navigation = { enabled: true }
    tool.save!
    tool
  end

  def feature_setup
    @account = Account.default
    toggle_k5_setting(@account)
  end

  def hex_value_for_color(element, style_type)
    "#" + ColorCommon.rgba_to_hex(element.style(style_type))
  end

  def new_announcement(course, title, message)
    course.announcements.create!(title:, message:)
  end

  def student_setup
    feature_setup
    @course_name = "K5 Course"
    @teacher_name = "K5Teacher"
    course_with_teacher(
      active_course: 1,
      active_enrollment: 1,
      course_name: @course_name,
      name: @teacher_name,
      email: "teacher_person@example.com"
    )
    @homeroom_teacher = @teacher
    course_with_student(
      active_all: true,
      name: "K5Student",
      course: @course
    )
    @original_student = @student
    @course.update!(homeroom_course: true)
    @homeroom_course = @course
    @subject_course_title = "Math"
    @student_enrollment = course_with_student(
      active_course: true,
      user: @student,
      course_name: @subject_course_title
    )
    @subject_course = @course
    @student_enrollment.update!(workflow_state: "active")
    @subject_course.enroll_teacher(@homeroom_teacher, enrollment_state: "active")
  end

  def observer_setup
    @observer = user_with_pseudonym(name: "Mom", email: "bestmom@example.com", workflow_state: "available")
    add_linked_observer(@student, @observer, root_account: @account)
  end

  def teacher_setup
    feature_setup
    @course_name = "K5 Course"
    course_with_teacher(
      active_course: 1,
      active_enrollment: 1,
      course_name: @course_name,
      name: "K5Teacher"
    )
    @homeroom_teacher = @teacher
    @course.update!(homeroom_course: true)
    @homeroom_course = @course

    @subject_course_title = "Math"
    course_with_teacher(
      active_course: 1,
      active_enrollment: 1,
      user: @homeroom_teacher,
      course_name: @subject_course_title
    )
    @subject_course = @course
  end

  def turn_on_learning_mastery_gradebook
    @subject_course.enable_feature!(:student_outcome_gradebook)
  end
end
