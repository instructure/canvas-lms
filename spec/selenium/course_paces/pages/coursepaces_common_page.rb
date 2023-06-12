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

module CoursePacesCommonPageObject
  def admin_setup
    feature_setup
    teacher_setup
    account_admin_user(account: @account)
  end

  def create_assignment(course, assignment_title, description, points_possible, publish_status)
    course.assignments.create!(
      title: assignment_title,
      description:,
      points_possible:,
      submission_types: "online_text_entry",
      workflow_state: publish_status
    )
  end

  def create_course_module(module_title, workflow_state = "active")
    @course.context_modules.create!(name: module_title, workflow_state:)
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

  def create_graded_discussion(course, discussion_title, workflow_state = "active")
    assignment = course.assignments.create!(name: discussion_title)
    course.discussion_topics.create!(user: @teacher,
                                     title: discussion_title,
                                     message: "Discussion topic message",
                                     assignment:,
                                     workflow_state:)
  end

  def create_quiz(course, quiz_title)
    due_at = 1.day.from_now(Time.zone.now)
    unlock_at = Time.zone.now.advance(days: -2)
    lock_at = Time.zone.now.advance(days: 4)
    title = quiz_title
    @context = course
    quiz = quiz_model
    quiz.generate_quiz_data
    quiz.due_at = due_at
    quiz.lock_at = lock_at
    quiz.unlock_at = unlock_at
    quiz.title = title
    quiz.save!
    quiz.quiz_questions.create!(
      question_data: {
        name: "Quiz Questions",
        question_type: "fill_in_multiple_blanks_question",
        question_text: "[color1]",
        answers: [{ text: "one", id: 1 }, { text: "two", id: 2 }, { text: "three", id: 3 }],
        points_possible: 1
      }
    )
    quiz.generate_quiz_data
    quiz.workflow_state = "available"
    quiz.save
    quiz.reload
    quiz
  end

  def create_published_course_pace(module_title, assignment_title)
    # We want the module item autopublish to happen immediately in test
    Setting.set("course_pace_publish_interval", "0")

    course_pace_model(course: @course, end_date: Time.zone.now.advance(days: 30))
    create_course_pace_module_with_assignment(module_title, assignment_title)
    @course_pace
  end

  def create_course_pace_module_with_assignment(module_title, assignment_title)
    @course_pace_module = create_course_module(module_title)
    @course_pace_assignment = create_assignment(@course, assignment_title, assignment_title, 10, "published")
    @course_pace_module.add_item(id: @course_pace_assignment.id, type: "assignment")
    @course_pace.course_pace_module_items.last.update! duration: 2
    run_jobs # Run the autopublish job
    @course_pace_module
  end

  def create_section_pace(section)
    course_section_pace = section_pace_model(section:)
    course_section_pace.publish
  end

  def create_student_pace(student_enrollment)
    student_pace = student_enrollment_pace_model(student_enrollment:)
    student_pace.publish
  end

  def disable_course_paces_in_course
    @course.update(enable_course_paces: false)
  end

  def enable_course_paces_in_course
    @course.update(enable_course_paces: true)
  end

  def feature_setup
    @account = Account.default
    @account.enable_feature!(:course_paces)
  end

  def skip_weekends(date, duration = 1)
    until duration == 0
      date += 1.day
      while date.wday == 0 || date.wday == 6
        date += 1.day
      end
      duration -= 1
    end
    date
  end

  def format_course_pacing_date(date)
    format_date_for_view(date, "%a, %b %-d, %Y")
  end

  def date_of_next(day)
    date  = Date.parse(day)
    delta = (date > Date.today) ? 0 : 7
    date + delta
  end

  def teacher_setup
    feature_setup
    @course_name = "course paces course"
    course_with_teacher(
      account: @account,
      active_course: 1,
      active_enrollment: 1,
      course_name: @course_name,
      name: "CoursePace Teacher"
    )
    @course.start_at = date_of_next("Monday") - 7.days
    @course.conclude_at = date_of_next("Monday") + 7.days
    @course.restrict_enrollments_to_course_dates = true
    @course.save!
  end

  def visit_course_paces_page(course_id_override: false)
    get "/courses/#{course_id_override || @course.id}/course_pacing"
  end
end
