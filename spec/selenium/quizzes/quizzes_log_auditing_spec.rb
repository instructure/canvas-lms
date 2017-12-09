#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_relative '../helpers/groups_common'

describe "quizzes log auditing" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include GroupsCommon

  context 'as a teacher' do
    before do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:quiz_log_auditing)
    end

    context 'attempt numbers' do
      it "should list the attempt number for a single attempt", priority: "2", test_id:605103 do
        @students = student_in_course(course: @course, name: 'student', active_all: true).user
        quiz = seed_quiz_with_submission
        sub = quiz.quiz_submissions.first

        get "/courses/#{@course.id}/quizzes/#{quiz.id}/submissions/#{sub.id}/log"
        expect(f('.ic-AttemptController__Attempt')).to include_text('1')
      end

      context 'multiple attempts' do
        before do
          student = student_in_course(course: @course, name: 'student', active_all: true).user
          quiz_create
          @quiz.allowed_attempts = 2
          @quiz.save

          generate_and_save_submission(@quiz, student)
          generate_and_save_submission(@quiz, student)

          @sub = @quiz.quiz_submissions.first
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@sub.id}/log"
        end

        it "should list the attempt number for multiple attempts", priority: "2", test_id:605106 do
          expect(ff('.ic-AttemptController__Attempt')[0]).to include_text('1')
          expect(ff('.ic-AttemptController__Attempt')[1]).to include_text('2')
        end

        it 'should toggle between attempts when clicking on the attempt', priority: "2", test_id:605107 do
          ff('.ic-AttemptController__Attempt')[0].click
          expect(driver.current_url).to include('attempt=1')
          ff('.ic-AttemptController__Attempt')[1].click
          expect(driver.current_url).to include('attempt=2')
        end
      end
    end

    context 'should list the attempt count for multiple attempts' do
      before do
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
        @quiz.allowed_attempts = 2
        @quiz.save

        @student = student_in_course(course: @course, name: 'student', active_all: true).user
        user_session(@student)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

        f('#take_quiz_link').click
        wait_for_ajaximations
      end

      it 'should show that a session had started and that it is has been read', priority: "2", test_id:605108 do
        skip_if_safari(:alert)
        scroll_page_to_bottom # the question viewed event is triggered by page scroll
        wait_for_ajax_requests
        submit_quiz

        sub = @quiz.quiz_submissions.where(:user_id => @student).first
        user_session(@teacher)

        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{sub.id}/log"
        expect(f('#ic-EventStream')).to include_text('Session started')
        expect(f('#ic-EventStream')).to include_text('Viewed (and possibly read)')
      end

      it 'should show that a question had been answered', priority: "2", test_id:605109 do
        answer_questions_and_submit(@quiz, 1)

        sub = @quiz.quiz_submissions.where(:user_id => @student).first
        user_session(@teacher)

        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{sub.id}/log"
        expect(f('#ic-EventStream')).to include_text('Answered question')
      end

      it 'should take you to a question when you click on the question number', priority: "2", test_id:605111 do
        answer_questions_and_submit(@quiz, 1)
        sub = @quiz.quiz_submissions.where(:user_id => @student).first
        user_session(@teacher)

        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{sub.id}/log"
        expect(f('#ic-EventStream')).to include_text('#1')
        fln('#1').click
        expect(f('.ic-QuestionInspector__QuestionHeader')).to include_text('Question #1')
      end
    end
  end
end
