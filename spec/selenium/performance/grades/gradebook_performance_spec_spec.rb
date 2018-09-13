#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative '../../grades/pages/gradezilla_page'
require_relative '../../grades/pages/speedgrader_page'

student_assignments = [
  [4000, 50],
  [2000,50],
  [1000,100],
  [200, 50]
]

describe 'Gradebook performance' do
  include_context 'in-process server selenium tests'

  before :once do
    grades_sample = (60.0..100.0).step(0.01).map { |x| x.round(2) }

    @course1 = course_factory(course_name: "My Course 1", active_course: true)
    @course1.enable_feature!(:new_gradebook)
    @teacher = course_with_teacher(course: @course1, name: 'Teacher Boss1', active_user: true, active_enrollment: true).user
    @students = create_users_in_course(@course1, student_assignments[0][0], return_type: :record, name_prefix: "Jack")
    group = @course1.assignment_groups.create! name: 'assignments'
    @assignments = create_assignments([@course1.id], student_assignments[0][1], points_possible: 100.0,
                                      submission_types: "online_text_entry,online_upload",
                                      assignment_group_id: group.id)
    # create graded submissions for each student, every assignment
    create_records(Submission, @assignments.map do |id|
      @students.map do |student|
        grade = grades_sample.sample
        {
          assignment_id: id,
          user_id: student.id,
          body: "hello",
          workflow_state: "graded",
          submission_type: 'online_text_entry',
          grader_id: @teacher.id,
          score: grade,
          grade: grade.to_s,
          graded_at: Time.zone.now,
          grade_matches_current_submission: true
        }
      end
    end.flatten)

    # create another course, reuse teacher and student to save time
    @course2 = course_factory(course_name: "My Course 2", active_course: true)
    @course2.enable_feature!(:new_gradebook)
    @course2.enroll_user(@teacher, 'TeacherEnrollment', allow_multiple_enrollments: true, enrollment_state: 'active')
    students = @students.first(student_assignments[1][0])
    create_enrollments(@course2, students, allow_multiple_enrollments: true)
    group = @course2.assignment_groups.create! name: 'assignments'
    @assignments2 = create_assignments([@course2.id], student_assignments[1][1], points_possible: 100.0,
                                       submission_types: "online_text_entry,online_upload",
                                       assignment_group_id: group.id)
    # create graded submissions for each student, every assignment
    create_records(Submission, @assignments2.map do |id|
      students.map do |student|
        grade = grades_sample.sample
        {
          assignment_id: id,
          user_id: student.id,
          body: "hello 2",
          workflow_state: "graded",
          submission_type: 'online_text_entry',
          grader_id: @teacher.id,
          score: grade,
          grade: grade.to_s,
          graded_at: Time.zone.now,
          grade_matches_current_submission: true
        }
      end
    end.flatten)

    # create another course, reuse teacher and student to save time
    @course3 = course_factory(course_name: "My Course 3", active_course: true)
    @course3.enable_feature!(:new_gradebook)
    @course3.enroll_user(@teacher, 'TeacherEnrollment', allow_multiple_enrollments: true, enrollment_state: 'active')
    students = @students.first(student_assignments[2][0])
    create_enrollments(@course3, students, allow_multiple_enrollments: true)
    group = @course3.assignment_groups.create! name: 'assignments'
    @assignments3 = create_assignments([@course3.id], student_assignments[2][1], points_possible: 100.0,
                                       submission_types: "online_text_entry,online_upload",
                                       assignment_group_id: group.id)
    # create graded submissions for each student, every assignment
    create_records(Submission, @assignments3.map do |id|
      students.map do |student|
        grade = grades_sample.sample
        {
          assignment_id: id,
          user_id: student.id,
          body: "hello 3",
          workflow_state: "graded",
          submission_type: 'online_text_entry',
          grader_id: @teacher.id,
          score: grade,
          grade: grade.to_s,
          graded_at: Time.zone.now,
          grade_matches_current_submission: true
        }
      end
    end.flatten)

    # create another course, reuse teacher and student to save time
    @course4 = course_factory(course_name: "My Course 4", active_course: true)
    @course4.enable_feature!(:new_gradebook)
    @course4.enroll_user(@teacher, 'TeacherEnrollment', allow_multiple_enrollments: true, enrollment_state: 'active')
    students = @students.first(student_assignments[3][0])
    create_enrollments(@course4, students, allow_multiple_enrollments: true)
    group = @course4.assignment_groups.create! name: 'assignments'
    @assignments4 = create_assignments([@course4.id], student_assignments[3][1], points_possible: 100.0,
                                       submission_types: "online_text_entry,online_upload",
                                       assignment_group_id: group.id)
    # create graded submissions for each student, every assignment
    create_records(Submission, @assignments4.map do |id|
      students.map do |student|
        grade = grades_sample.sample
        {
          assignment_id: id,
          user_id: student.id,
          body: "hello 4",
          workflow_state: "graded",
          submission_type: 'online_text_entry',
          grader_id: @teacher.id,
          score: grade,
          grade: grade.to_s,
          graded_at: Time.zone.now,
          grade_matches_current_submission: true
        }
      end
    end.flatten)
  end

  before :each do
    user_session(@teacher)
  end

  context '200,000 submissions' do
    it 'gradezilla loads in less than 25 seconds' do
      page_load_start_time = Time.zone.now
      Gradezilla.visit(@course1)
      wait_for_ajaximations
      page_load_end_time = Time.zone.now
      expect(page_load_end_time - page_load_start_time).to be < 25
    end

    it 'speedgrader loads in less than 100 seconds' do
      skip('load times are pretty inconsistent')
      page_load_start_time = Time.zone.now
      Speedgrader.visit(@course1.id, @assignments[0])
      wait_for_ajaximations
      page_load_end_time = Time.zone.now
      expect(page_load_end_time - page_load_start_time).to be < 100
    end
  end

  context '100,000 submissions 2000x50' do
    it 'gradezilla loads in less than 25 seconds' do
      page_load_start_time = Time.zone.now
      Gradezilla.visit(@course2)
      wait_for_ajaximations
      page_load_end_time = Time.zone.now
      expect(page_load_end_time - page_load_start_time).to be < 25
    end

    it 'speedgrader loads in less than 40 seconds' do
      page_load_start_time = Time.zone.now
      Speedgrader.visit(@course2.id, @assignments2[0])
      wait_for_ajaximations
      page_load_end_time = Time.zone.now
      expect(page_load_end_time - page_load_start_time).to be < 40
    end
  end

  context '100,000 submissions 1000x100' do
    it 'gradezilla loads in less than 25 seconds' do
      page_load_start_time = Time.zone.now
      Gradezilla.visit(@course3)
      wait_for_ajaximations
      wait_for_ajaximations
      page_load_end_time = Time.zone.now
      expect(page_load_end_time - page_load_start_time).to be < 25
    end

    it 'speedgrader loads in less than 19 seconds' do
      page_load_start_time = Time.zone.now
      Speedgrader.visit(@course3.id, @assignments3[0])
      wait_for_ajaximations
      page_load_end_time = Time.zone.now
      expect(page_load_end_time - page_load_start_time).to be < 19
    end
  end

  context '10,000 submissions' do
    it 'gradezilla loads in less than 18 seconds' do
      page_load_start_time = Time.zone.now
      Gradezilla.visit(@course4)
      wait_for_ajaximations
      page_load_end_time = Time.zone.now
      expect(page_load_end_time - page_load_start_time).to be < 18
    end

    it 'speedgrader loads in less than 10 seconds' do
      page_load_start_time = Time.zone.now
      Speedgrader.visit(@course4.id, @assignments4[0])
      wait_for_ajaximations
      page_load_end_time = Time.zone.now
      expect(page_load_end_time - page_load_start_time).to be < 10
    end
  end
end
