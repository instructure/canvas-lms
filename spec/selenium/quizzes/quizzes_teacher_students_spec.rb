#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe 'quizzes students' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context 'with a teacher' do
    before :each do
      course_with_teacher_logged_in
      @quiz = @course.quizzes.create!(title: 'new quiz')
      @quiz.quiz_questions.create!(
        question_data: {
          name: 'test 3',
          question_type: 'multiple_choice_question',
          answers: {
            answer_0: { answer_text: '0' },
            answer_1: { answer_text: '1' }
          }
        }
      )
      @quiz.generate_quiz_data
      @quiz.workflow_state = 'available'
      @quiz.save
    end

    it "should not show 'take quiz' button after the allowed attempts are over", priority: "1", test_id: 333736 do
      student = student_in_course(course: @course, name: 'student', active_all: true).user
      @quiz.allowed_attempts = 2
      @quiz.save
      user_session(student)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      f('#take_quiz_link').click
      wait_for_ajaximations
      answer_questions_and_submit(@quiz, 1)

      expect(f('#take_quiz_link')).to be_present
      f('#take_quiz_link').click
      wait_for_ajaximations
      answer_questions_and_submit(@quiz, 1)

      expect(f("#content")).not_to contain_css('#take_quiz_link')
    end

    context 'when using the course student view' do
      it 'can take a quiz', priority: "1", test_id: 210050 do
        # Note: this is different from masquerading!
        @fake_student = @course.student_view_student
        enter_student_view
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

        wait_for_new_page_load { f('#take_quiz_link').click }

        q = @quiz.stored_questions[0]

        fj("input[type=radio][value=#{q[:answers][0][:id]}]").click
        expect(fj("input[type=radio][value=#{q[:answers][0][:id]}]").selected?).to be_truthy

        scroll_into_view '#submit_quiz_form .btn-primary'
        f('#submit_quiz_form .btn-primary').click

        expect(f('.quiz-submission .quiz_score .score_value')).to be_displayed
        quiz_sub = @fake_student.reload.submissions.where(assignment_id: @quiz.assignment).first
        expect(quiz_sub).to be_present
        expect(quiz_sub.workflow_state).to eq 'graded'
      end
    end
  end
end
