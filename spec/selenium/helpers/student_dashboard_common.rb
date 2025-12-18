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
    feature_status ? Account.default.root_account.enable_feature!(:widget_dashboard) : Account.default.root_account.disable_feature!(:widget_dashboard)
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

  def workflow_edge_case_course_setup
    @course4 = course_factory(active_all: true, course_name: "Course 3")
    @teacher3 = user_factory(active_all: true, name: "Kevin White")
    @student3 = user_factory(active_all: true, name: "Laura Green")

    @course4.enroll_teacher(@teacher3, enrollment_state: :active)
    @course4.enroll_student(@student3, enrollment_state: :active)
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
    @due_graded_discussion = @course1.assignments.create!(name: "Course 1: due_graded_discussion", points_possible: "10", due_at: 6.days.from_now.end_of_day, submission_types: "discussion_topic")
    @due_assignment = @course1.assignments.create!(name: "Course 1: due_assignment", points_possible: "10", due_at: 1.day.from_now.end_of_day, submission_types: "online_text_entry")
    @due_quiz = @course1.assignments.create!(title: "Course 1: due_quiz", points_possible: "10", due_at: 13.days.from_now.end_of_day, submission_types: "online_quiz")

    @missing_graded_discussion = @course1.assignments.create!(name: "Course 1: missing_graded_discussion", points_possible: "10", due_at: 2.days.ago.end_of_day, submission_types: "discussion_topic")
    @missing_assignment = @course2.assignments.create!(name: "Course 2: missing_assignment", points_possible: "10", due_at: 3.days.ago.end_of_day, submission_types: "online_text_entry")
    @missing_quiz = @course2.assignments.create!(title: "Course 2: missing_quiz", points_possible: "10", due_at: 4.days.ago.end_of_day, submission_types: "online_quiz")

    @graded_discussion = @course1.assignments.create!(name: "Course 1: graded_discussion", points_possible: "10", due_at: 5.days.ago.end_of_day, submission_types: "discussion_topic")
    @graded_assignment = @course2.assignments.create!(name: "Course 2: graded_assignment", points_possible: "10", due_at: 3.days.ago.end_of_day, submission_types: "online_text_entry")
    @submitted_discussion = @course2.assignments.create!(name: "Course 2: submitted_discussion", points_possible: "10", due_at: 2.days.ago.end_of_day, submission_types: "discussion_topic")
    @submitted_assignment = @course1.assignments.create!(name: "Course 1: submitted_assignment", points_possible: "10", due_at: 1.day.from_now.end_of_day, submission_types: "online_text_entry")
  end

  def dashboard_course_submission_setup
    @submitted_assignment.submit_homework(@student, submission_type: "online_text_entry")
    @submitted_discussion.submit_homework(@student, submission_type: "discussion_topic")

    @graded_assignment.submit_homework(@student, submission_type: "online_text_entry")
    @graded_discussion.submit_homework(@student, submission_type: "discussion_topic")

    @graded_quiz = @course1.quizzes.create!(title: "submitted_quiz", due_at: 1.day.from_now.end_of_day)
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
      assignment = @course1.assignments.create!(name: "Course1: HW due in #{i + 1} days", points_possible: "10", due_at: (i + 1).days.from_now.end_of_day, submission_types: "online_text_entry")
      @course1.assignments.create!(name: "Course1: HW due in #{i + 2} days", points_possible: "10", due_at: (i + 2).days.from_now.end_of_day, submission_types: "online_text_entry")
      @course2.assignments.create!(name: "Course2: HW due in #{i + 3} days", points_possible: "10", due_at: (i + 3).days.from_now.end_of_day, submission_types: "online_text_entry")
      @course1.assignments.create!(name: "Course1: Missing HW #{i + 1} days", points_possible: "10", due_at: (i + 1).days.ago.end_of_day, submission_types: "online_text_entry")
      @course2.assignments.create!(name: "Course2: Missing HW #{i + 1} days", points_possible: "10", due_at: (i + 1).days.ago.end_of_day, submission_types: "online_text_entry")
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

    @assignment_pending_course = @course3.assignments.create!(name: "Course 3: due_graded_discussion", points_possible: "10", due_at: 2.days.from_now.end_of_day, submission_types: "discussion_topic")
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

  def multi_section_course_setup
    # Create a course with multiple sections and a instructor shared across all sections
    @multi_course = course_factory(active_all: true, course_name: "Multi-Section Course")
    @section1 = @multi_course.default_section
    @section2 = @multi_course.course_sections.create!(name: "Section 2")
    @section3 = @multi_course.course_sections.create!(name: "Section 3")
    @section4 = @multi_course.course_sections.create!(name: "Section 4")

    @multi_stu_sec1 = user_factory(active_all: true, name: "Student 2")
    @multi_stu_sec2 = user_factory(active_all: true, name: "Student 3")
    @shared_teacher = user_factory(active_all: true, name: "Shared Teacher")

    @multi_course.enroll_student(@multi_stu_sec1, section: @section1, enrollment_state: "active", allow_multiple_enrollments: true)
    @multi_course.enroll_student(@multi_stu_sec2, section: @section2, enrollment_state: "active", allow_multiple_enrollments: true)
    @multi_course.enroll_teacher(@shared_teacher, section: @section1, enrollment_state: "active", allow_multiple_enrollments: true)
    @multi_course.enroll_teacher(@shared_teacher, section: @section2, enrollment_state: "active", allow_multiple_enrollments: true)
    @multi_course.enroll_teacher(@shared_teacher, section: @section3, enrollment_state: "active", allow_multiple_enrollments: true)
  end

  def section_specific_announcements_setup
    @multi_course.enroll_student(@multi_stu_sec1, section: @section3, enrollment_state: "active", allow_multiple_enrollments: true)

    @section1_ann1 = @multi_course.announcements.create!(title: "section 1", message: "section 1- specific", is_section_specific: true, course_sections: [@section1])
    @section2_ann2 = @multi_course.announcements.create!(title: "section 2", message: "section 2- specific", is_section_specific: true, course_sections: [@section2])
    @section3_ann3 = @multi_course.announcements.create!(title: "section 3", message: "section 3- specific", is_section_specific: true, course_sections: [@section3])
    @section1_2_ann4 = @multi_course.announcements.create!(title: "section 1 & 2", message: "section 1 & 2 specific", is_section_specific: true, course_sections: [@section1, @section2])
    @section2_3_ann5 = @multi_course.announcements.create!(title: "section 2 & 3", message: "section 2 & 3 specific", is_section_specific: true, course_sections: [@section2, @section3])
    @section1_2_3_ann6 = @multi_course.announcements.create!(title: "section 1 & 2 & 3", message: "section 1 & 2 & 3 specific", is_section_specific: true, course_sections: [@section1, @section2, @section3])
    @section2_4_ann7 = @multi_course.announcements.create!(title: "section 2 & 4", message: "section 2 & 4 specific", is_section_specific: true, course_sections: [@section2, @section4])
  end

  def section_specific_assignments_setup
    @multi_course.enroll_student(@multi_stu_sec1, section: @section3, enrollment_state: "active", allow_multiple_enrollments: true)

    @section1_hw1 = @multi_course.assignments.create!(name: "Section 1 Assignment", points_possible: "10", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
    @section2_hw2 = @multi_course.assignments.create!(name: "Section 2 Assignment", points_possible: "10", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
    @section3_hw3 = @multi_course.assignments.create!(name: "Section 3 Assignment", points_possible: "10", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
    @section1_2_hw4 = @multi_course.assignments.create!(name: "Section 1 & 2 Assignment", points_possible: "10", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
    @section2_3_hw5 = @multi_course.assignments.create!(name: "Section 2 & 3 Assignment", points_possible: "10", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
    @section1_2_3_hw6 = @multi_course.assignments.create!(name: "Section 1 & 2 & 3 Assignment", points_possible: "10", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")
    @section2_4_hw7 = @multi_course.assignments.create!(name: "Section 2 & 4 Assignment", points_possible: "10", due_at: 2.days.from_now.end_of_day, submission_types: "online_text_entry")

    create_section_override_for_assignment(@section1_hw1, course_section: @section1)
    create_section_override_for_assignment(@section2_hw2, course_section: @section2)
    create_section_override_for_assignment(@section3_hw3, course_section: @section3)
    create_section_override_for_assignment(@section1_2_hw4, course_section: @section1)
    create_section_override_for_assignment(@section1_2_hw4, course_section: @section2)
    create_section_override_for_assignment(@section2_3_hw5, course_section: @section2)
    create_section_override_for_assignment(@section2_3_hw5, course_section: @section3)
    create_section_override_for_assignment(@section1_2_3_hw6, course_section: @section1)
    create_section_override_for_assignment(@section1_2_3_hw6, course_section: @section2)
    create_section_override_for_assignment(@section1_2_3_hw6, course_section: @section3)
    create_section_override_for_assignment(@section2_4_hw7, course_section: @section2)
    create_section_override_for_assignment(@section2_4_hw7, course_section: @section4)

    @section1_hw1.update!(only_visible_to_overrides: true)
    @section2_hw2.update!(only_visible_to_overrides: true)
    @section3_hw3.update!(only_visible_to_overrides: true)
    @section1_2_hw4.update!(only_visible_to_overrides: true)
    @section2_3_hw5.update!(only_visible_to_overrides: true)
    @section1_2_3_hw6.update!(only_visible_to_overrides: true)
    @section2_4_hw7.update!(only_visible_to_overrides: true)
  end

  def observer_w_section_specific_course_setup
    @multi_section_observer = user_factory(name: "Observer3", active_all: true)
    @multi_course.enroll_user(@multi_section_observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @multi_stu_sec1, allow_multiple_enrollments: true)
    @multi_course.enroll_user(@multi_section_observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @multi_stu_sec2, allow_multiple_enrollments: true)
  end

  def group_assignment_course_setup
    workflow_edge_case_course_setup
    @student1_group1 = user_factory(active_all: true, name: "Student 1")
    @student2_group1 = user_factory(active_all: true, name: "Student 2")
    @student_no_group = user_factory(active_all: true, name: "Student No Group")

    @course4.enroll_student(@student1_group1, enrollment_state: :active)
    @course4.enroll_student(@student2_group1, enrollment_state: :active)
    @course4.enroll_student(@student_no_group, enrollment_state: :active)

    # Create group set and groups
    @group_category = @course4.group_categories.create!(name: "Project Groups")
    @group1 = @course4.groups.create!(name: "Group 1", group_category: @group_category)
    @group2 = @course4.groups.create!(name: "Group 2", group_category: @group_category)

    @group1.add_user(@student1_group1)
    @group1.add_user(@student2_group1)
    @group2.add_user(@student3)
  end

  def group_assignment_setup
    @group_assignment_graded_individually = @course4.assignments.create!(
      name: "Graded Individually",
      due_at: 2.days.from_now.end_of_day,
      submission_types: "online_text_entry",
      group_category: @group_category,
      grade_group_students_individually: true,
      points_possible: 10,
      only_visible_to_overrides: true
    )
    @missing_group_assignment = @course4.assignments.create!(
      name: "missing Group assignment",
      due_at: 3.days.ago.end_of_day,
      submission_types: "online_text_entry",
      group_category: @group_category,
      grade_group_students_individually: false,
      points_possible: 10,
      only_visible_to_overrides: true
    )
    @missing_graded_individually = @course4.assignments.create!(
      name: "missing Graded Individually group assignment",
      due_at: 3.days.ago.end_of_day,
      submission_types: "online_text_entry",
      group_category: @group_category,
      grade_group_students_individually: true,
      points_possible: 10,
      only_visible_to_overrides: true
    )
    create_group_override_for_assignment(@group_assignment_graded_individually, group: @group1)
    create_group_override_for_assignment(@missing_group_assignment, group: @group1, due_at: 3.days.ago.end_of_day)
    create_group_override_for_assignment(@missing_graded_individually, group: @group1, due_at: 3.days.ago.end_of_day)
  end

  def submit_group_assignment
    @group_assignment.submit_homework(@student1_group1,
                                      submission_type:
                                      "online_text_entry",
                                      body: "Group submission")
    @group_assignment_graded_individually.submit_homework(@student1_group1,
                                                          submission_type:
                                                          "online_text_entry",
                                                          body: "Individual submission")
  end
end
