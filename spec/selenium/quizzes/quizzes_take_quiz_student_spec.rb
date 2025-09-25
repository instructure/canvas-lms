# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/quizzes_common"

describe "taking a quiz" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context "as a student" do
    before(:once) do
      course_with_teacher(active_all: 1)
      course_with_student(course: @course, active_all: 1)
    end

    before { user_session(@student) }

    context "when the quiz is past due" do
      let(:quiz_past_due) do
        quiz_past_due = quiz_create(course: @course)
        quiz_past_due.due_at = default_time_for_due_date(2.days.ago)
        quiz_past_due.save!
        quiz_past_due.reload
      end

      it 'shows the submission as late on the submission details page and marks it as "late"', custom_timeout: 30 do
        take_and_answer_quiz(quiz: quiz_past_due)
        verify_quiz_submission_is_late
        verify_quiz_submission_is_late_in_speedgrader
      end
    end

    context "when the quiz has an access code" do
      let(:access_code) { "1234" }
      let(:quiz) do
        @context = @course
        quiz = quiz_model
        2.times { quiz.quiz_questions.create! question_data: true_false_question_data }
        quiz.access_code = access_code
        quiz.generate_quiz_data
        quiz.save!
        quiz.reload
      end

      context 'when the quiz has "One Question at a Time" enabled' do
        let(:oqaat_quiz) do
          @context = @course
          quiz = quiz_model
          2.times { quiz.quiz_questions.create! question_data: true_false_question_data }
          quiz.access_code = access_code
          quiz.title = "OQAAT quiz"
          quiz.one_question_at_a_time = true
          quiz.generate_quiz_data
          quiz.save!
          quiz.reload
        end

        def verify_no_access_code_reprompts_during_oqaat_quiz
          take_and_answer_quiz(
            submit: false,
            access_code:,
            quiz: oqaat_quiz
          )

          yield if block_given?

          # select second question
          select_question_from_column_links(@quiz.quiz_questions[1].id)
          verify_no_access_code_prompt

          # answer second question
          answer_question(@quiz.stored_questions[1][:answers][0][:id])

          submit_quiz

          verify_no_access_code_prompt
        end

        def verify_no_access_code_prompt
          expect(f("#content")).not_to contain_css("#quiz_access_code")
        end

        it "only asks once for the access code", priority: "1" do
          verify_no_access_code_reprompts_during_oqaat_quiz
        end

        it "does not prompt for access code for sidebar question navigation" do
          verify_no_access_code_reprompts_during_oqaat_quiz do
            select_question_from_column_links(@quiz.quiz_questions[0].id)
            select_question_from_column_links(@quiz.quiz_questions[1].id)
          end
        end
      end
    end
  end
end
