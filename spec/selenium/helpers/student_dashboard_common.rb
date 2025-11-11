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

module StudentDashboardCommon
  def set_widget_dashboard_flag(feature_status: true)
    feature_status ? @course1.root_account.enable_feature!(:widget_dashboard) : @course1.root_account.disable_feature!(:widget_dashboard)
  end

  def dashboard_student_setup
    @course1 = course_factory(active_all: true, course_name: "Course 1")
    @course2 = course_factory(active_all: true, course_name: "Course 2")

    @teacher1 = user_factory(active_all: true, name: "Nancy Smith")
    @teacher2 = user_factory(active_all: true, name: "John Doe")
    @student = user_factory(active_all: true, name: "Jane Brown")

    @course1.enroll_teacher(@teacher1, enrollment_state: :active)
    @course2.enroll_teacher(@teacher2, enrollment_state: :active)
    @course1.enroll_student(@student, enrollment_state: :active)
    @course2.enroll_student(@student, enrollment_state: :active)
  end

  def pagination_course_setup
    20.times do |i|
      course = course_with_teacher(name: "Teacher #{i + 3}", course_name: "Course #{i + 3}", active_all: true).course
      course.enroll_student(@student, enrollment_state: :active)
    end
  end

  def dashboard_announcement_setup
    @announcement1 = @course1.announcements.create!(title: "Course 1 - Announcement title 1", message: "Announcement message 1")
    @announcement2 = @course2.announcements.create!(title: "Course 2 - Announcement title 2", message: "Announcement message 2")
    @announcement3 = @course1.announcements.create!(title: "Course 1 - Announcement title 3", message: "Announcement message 3")
    @announcement4 = @course2.announcements.create!(title: "Course 2 - Announcement title 4", message: "Announcement message 4")
    @announcement5 = @course1.announcements.create!(title: "Course 1 - Announcement title 5", message: "Announcement message 5")
    @announcement6 = @course2.announcements.create!(title: "Course 2 - Announcement title 6", message: "Announcement message 6")
    @announcement7 = @course1.announcements.create!(title: "Course 1 - Announcement title 7", message: "Announcement message 7. This is a longer message to test the read more link functionality on the announcements widget. This message should be long enough to be truncated.")

    @announcement6.discussion_topic_participants.find_by(user: @student)&.update!(workflow_state: "read")
    @announcement5.discussion_topic_participants.find_by(user: @student)&.update!(workflow_state: "read")
  end

  def pagination_announcement_setup
    15.times do |i|
      read_announcement = @course1.announcements.create!(title: "Announcement #{i + 1}", message: "message #{i + 1}")
      read_announcement.discussion_topic_participants.find_by(user: @student)&.update!(workflow_state: "read")
    end

    11.times do |i|
      @course1.announcements.create!(title: "Announcement #{i + 11}", message: "message #{i + 11}")
    end
  end

  def dashboard_people_setup
    @ta1 = course_with_ta(name: "Alice Davis", course: @course1, active_all: true).user
    @ta2 = course_with_ta(name: "Bob Johnson", course: @course2, active_all: true).user
  end

  def dashboard_course_assignment_setup
    @due_graded_discussion = @course1.assignments.create!(name: "Course 1: due_graded_discussion", points_possible: "10", due_at: 6.days.from_now, submission_types: "discussion_topic")
    @due_assignment = @course1.assignments.create!(name: "Course 1: due_assignment", points_possible: "10", due_at: 1.day.from_now, submission_types: "online_text_entry")
    @due_quiz = @course1.assignments.create!(title: "Course 1: due_quiz", points_possible: "10", due_at: 13.days.from_now, submission_types: "online_quiz")

    @missing_graded_discussion = @course1.assignments.create!(name: "Course 1: missing_graded_discussion", points_possible: "10", due_at: 2.days.ago, submission_types: "discussion_topic")
    @missing_assignment = @course2.assignments.create!(name: "Course 2: missing_assignment", points_possible: "10", due_at: 3.days.ago, submission_types: "online_text_entry")
    @missing_quiz = @course2.assignments.create!(title: "Course 2: missing_quiz", points_possible: "10", due_at: 4.days.ago, submission_types: "online_quiz")

    @graded_discussion = @course1.assignments.create!(name: "Course 1: graded_discussion", points_possible: "10", due_at: 5.days.ago, submission_types: "discussion_topic")
    @graded_assignment = @course2.assignments.create!(name: "Course 2: graded_assignment", points_possible: "10", due_at: 3.days.ago, submission_types: "online_text_entry")

    @submitted_discussion = @course2.assignments.create!(name: "Course 2: submitted_discussion", points_possible: "10", due_at: 2.days.ago, submission_types: "discussion_topic")
    @submitted_assignment = @course1.assignments.create!(name: "Course 1: submitted_assignment", points_possible: "10", due_at: 1.day.from_now, submission_types: "online_text_entry")
  end

  def dashboard_course_submission_setup
    @submitted_assignment.submit_homework(@student, submission_type: "online_text_entry")
    @submitted_discussion.submit_homework(@student, submission_type: "discussion_topic")

    @graded_assignment.submit_homework(@student, submission_type: "online_text_entry")
    @graded_discussion.submit_homework(@student, submission_type: "discussion_topic")

    @graded_quiz = @course1.quizzes.create!(title: "submitted_quiz", due_at: 1.day.from_now)
    @graded_quiz.quiz_questions.create!(question_data: { question_type: "true_false_question", points_possible: 10 })
    @graded_quiz.generate_quiz_data
    @graded_quiz.workflow_state = "available"
    @graded_quiz.save!
    qs = @graded_quiz.generate_submission(@student)
    qs.submission_data
    Quizzes::SubmissionGrader.new(qs).grade_submission
  end

  def pagination_submission_setup
    14.times do |i|
      assignment = @course1.assignments.create!(name: "Course1: HW due in #{i + 1} days", points_possible: "10", due_at: (i + 1).days.from_now, submission_types: "online_text_entry")
      @course1.assignments.create!(name: "Course1: HW due in #{i + 2} days", points_possible: "10", due_at: (i + 2).days.from_now, submission_types: "online_text_entry")
      @course2.assignments.create!(name: "Course2: HW due in #{i + 3} days", points_possible: "10", due_at: (i + 3).days.from_now, submission_types: "online_text_entry")
      @course1.assignments.create!(name: "Course1: Missing HW #{i + 1} days", points_possible: "10", due_at: (i + 1).days.ago, submission_types: "online_text_entry")
      @course2.assignments.create!(name: "Course2: Missing HW #{i + 1} days", points_possible: "10", due_at: (i + 1).days.ago, submission_types: "online_text_entry")

      assignment.submit_homework(@student, submission_type: "online_text_entry")
    end
  end

  def dashboard_course_grade_setup
    @graded_assignment.grade_student(@student, grade: "8", grader: @teacher2)
    @graded_discussion.grade_student(@student, grade: "9", grader: @teacher1)
  end

  def observed_student_setup
    @student2 = user_factory(active_all: true, name: "student2")
    @course1.enroll_student(@student2, enrollment_state: :active)
    @course2.enroll_student(@student2, enrollment_state: :active)

    @submitted_discussion.submit_homework(@student2, submission_type: "discussion_topic")
    @graded_assignment.submit_homework(@student2, submission_type: "online_text_entry")
    @graded_assignment.grade_student(@student2, grade: "10", grader: @teacher2)
  end

  def observer_setup
    @observer = user_factory(name: "Observer", active_all: true)

    @course1.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student })
    @course2.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student2 })
  end

  def dashboard_pending_enrollment_setup
    @course3 = course_factory(active_all: true, course_name: "Test Course")

    @assignment_pending_course = @course3.assignments.create!(name: "Course 3: due_graded_discussion", points_possible: "10", due_at: 2.days.from_now, submission_types: "discussion_topic")
    @course3.enroll_teacher(@teacher1, enrollment_state: :active)
    @announcement_pending_course = @course3.announcements.create!(title: "Course 3 - Announcement", message: "Announcement message for pending enrollment course")
  end

  def dashboard_inactive_courses_setup
    @student_w_inactive = user_factory(active_all: true, name: "Student-W Inactive-courses")

    @past_course = course_factory(active_all: true, course_name: "Past Course")
    @past_course.enroll_student(@student_w_inactive, enrollment_state: "active")
    @past_course.update!(conclude_at: 1.week.ago, restrict_enrollments_to_course_dates: true)

    @concluded_course = course_factory(active_all: true, course_name: "Concluded Course")
    student_enroll1 = @concluded_course.enroll_student(@student_w_inactive, enrollment_state: "active")
    student_enroll1.workflow_state = "completed"
    student_enroll1.save!

    @unpublished_course = course_factory(active_all: true, course_name: "Unpublished Course")
    student_enroll2 = @unpublished_course.enroll_student(@student_w_inactive, enrollment_state: "active")
    student_enroll2.workflow_state = "creation_pending"
    student_enroll2.save!
  end

  def observer_w_inactive_courses_setup
    @observer = user_factory(name: "Observer2", active_all: true)
    @past_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student_w_inactive)
    observer_enroll2 = @concluded_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student_w_inactive)
    observer_enroll2.workflow_state = "completed"
    observer_enroll2.save!

    observer_enroll2 = @unpublished_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student_w_inactive)
    observer_enroll2.workflow_state = "creation_pending"
    observer_enroll2.save!
    @course1.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student })
    @course1.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student_w_inactive })
  end
end
