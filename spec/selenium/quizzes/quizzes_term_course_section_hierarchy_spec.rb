#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/quizzes_common'

describe "quizzes section hierarchy" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before :each do
    course_with_teacher_logged_in
    @new_section = @course.course_sections.create!(name: 'New Section')
    @student = student_in_section(@new_section)
    @course.start_at = Time.zone.now.advance(days: -30)
    @course.conclude_at = Time.zone.now.advance(days: -10)
    @course.restrict_enrollments_to_course_dates = true
    @course.save!
    @new_section.start_at = Time.zone.now.advance(days: -30)
    @new_section.end_at = Time.zone.now.advance(days: 10)
    @new_section.restrict_enrollments_to_section_dates = true
    @new_section.save!

    # create a quiz and assign it to the section with due dae after course end date
    @quiz = quiz_with_multiple_type_questions(false)
    @quiz.reload
    @override = @quiz.assignment_overrides.build
    @override.set = @new_section
    @override.due_at = Time.zone.now.advance(days:3)
    @override.due_at_overridden = true
    @override.save!
  end

  def take_hierarchy_quiz
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load{f('#take_quiz_link').click}
    # make sure it does not create a blank submissions
    expect(f("#content")).not_to contain_css('.quiz_score')
    expect(f("#content")).not_to contain_css('.quiz_duration')
    # take and submit the quiz
    answer_questions_and_submit(@quiz, 3)
  end

  def verify_quiz_accessible
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load{f('#take_quiz_link').click}
    # make sure it does not create a blank submissions
    expect(f("#content")).not_to contain_css('.quiz_score')
    expect(f("#content")).not_to contain_css('.quiz_duration')
    f('#section-tabs .quizzes').click
    accept_alert
    wait_for_ajaximations
  end

  context "section overrides course and term hierarchy" do
    context "course end date in past" do
      it "should allow the student to take the quiz", priority: "1", test_id: 282619 do
        # ensure student is able to take the quiz and it does not create a blank submission
        user_session(@student)
        take_hierarchy_quiz
      end

      it "should allow the teacher to preview the quiz", priority: "1", test_id: 282838 do
        get "/courses/#{@course.id}/quizzes"
        fln('Test Quiz').click
        expect_new_page_load{f('#preview_quiz_button').click}
        expect(f(' .quiz-header')).to include_text('This is a preview of the published version of the quiz')
      end

      it "should work with lock and unlock dates set up", priority: "1", test_id: 323086 do
        @override.unlock_at = Time.zone.now.advance(days:-1)
        @override.lock_at = Time.zone.now.advance(days:4)
        user_session(@student)
        take_hierarchy_quiz
      end
    end

    context "term end date in past" do
      before :each do
        term = EnrollmentTerm.find(@course.enrollment_term_id)
        term.start_at = Time.zone.now.advance(days: -60)
        term.end_at = Time.zone.now.advance(days: -15)
        term.save!
      end

      it "should still be accessible for student in the section after term end date", priority: "1", test_id: 323087 do
        user_session(@student)
        take_hierarchy_quiz
      end

      it "should work with lock and unlock dates set up", priority: "1", test_id: 323090 do
        @override.unlock_at = Time.zone.now.advance(days:-1)
        @override.lock_at = Time.zone.now.advance(days:4)
        user_session(@student)
        take_hierarchy_quiz
      end

      it "should not be accessible for student in the main section", priority: "1", test_id: 350077 do
        student1 = user_with_pseudonym(username: 'student1@example.com', active_all: 1)
        student_in_course(course: @course, user: student1)
        user_session(student1)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f('#quiz_show .quiz-header .lock_explanation').text).
            to include('This quiz is no longer available as the course has been concluded')
      end
    end
  end

  context "course overrides hierarchy when restrict to section dates is not checked" do
    before :each do
      @new_section.restrict_enrollments_to_section_dates = false
      @new_section.save!
    end

    context "course ends in past" do
      it "should disallow student to view quiz", priority: "1", test_id: 323323 do
        user_session(@student)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f('#quiz_show .quiz-header .lock_explanation').text).
                                        to include('This quiz is no longer available as the course has been concluded')
      end
    end

    context "course ends in future" do
      before :each do
        @course.conclude_at = Time.zone.now.advance(days: 10)
        @course.save!
      end

      it "should allow student in section to take quiz", priority: "1", test_id: 323321 do
        skip_if_safari(:alert)
        user_session(@student)
        verify_quiz_accessible
      end
    end
  end

  context "term overrides hierarchy when restrict to course and section dates are not checked" do
    context "course ends in past" do
      before :each do
        @course.restrict_enrollments_to_course_dates = false
        @course.save!
        @new_section.restrict_enrollments_to_section_dates = false
        @new_section.save!
      end

      it "should allow student to take quiz", priority: "1", test_id: 323326 do
        skip_if_safari(:alert)
        user_session(@student)
        verify_quiz_accessible
      end

      it "should allow students in the main section to take the quiz", priority: "1", test_id: 350075 do
        student1 = user_with_pseudonym(username: 'student1@example.com', active_all: 1)
        enrollment = student_in_course(course: @course, user: student1)
        enrollment.accept!
        user_session(student1)
        verify_quiz_accessible
      end
    end
  end
end
