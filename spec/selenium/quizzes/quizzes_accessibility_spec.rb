#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe 'quizzes accessibility' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before(:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
  end

  it 'renders all answer arrows accessible to a screen reader', priority: "2", test_id: 209355 do
    skip('started failing around Mar 20, 2016 - need investigation')
    skip_if_chrome('Can not get to student view in Chrome')
    # -------------------------------------------------------------------------
    # adapted from:
    #   file: quizzes_question_creation_spec
    #   spec: should create a quiz with a variety of quiz questions
    #
    quiz = @last_quiz

    create_multiple_choice_question     # 1x labelled <input /> here

    click_new_question_button
    create_multiple_choice_question     # 2x labelled <input /> here (we will answer incorrectly)

    click_new_question_button
    create_true_false_question          # 2x labelled <input /> here

    click_new_question_button
    create_fill_in_the_blank_question   # 0x labelled <input /> here

    quiz.reload
    refresh_page # making sure the quizzes load up from the database
    click_questions_tab

    4.times do |i|
      expect(f("#question_#{quiz.quiz_questions[i].id}")).to be_truthy
    end

    questions = ff('.display_question')
    expect(questions[0]).to have_class('multiple_choice_question')
    expect(questions[1]).to have_class('multiple_choice_question')
    expect(questions[2]).to have_class('true_false_question')
    expect(questions[3]).to have_class('short_answer_question')

    #
    # end of adapted code
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    # snippet from:
    #   file: teacher_quizzes_statistics_spec
    #   symbol: publish_the_quiz
    quiz.workflow_state = 'available'
    quiz.generate_quiz_data
    quiz.published_at = Time.zone.now
    quiz.save!
    # --
    # -------------------------------------------------------------------------
    # snippet from:
    #   file: teacher_quizzes_students_spec
    #   spec: should allow a student view student to take a quiz
    @fake_student = @course.student_view_student
    enter_student_view
    get "/courses/#{@course.id}/quizzes/#{quiz.id}"
    f('#take_quiz_link').click
    wait_for_ajaximations
    # --

    # choose a correct multiple-choice answer
    q = quiz.stored_questions[0]
    f("#question_#{q[:id]}_answer_#{q[:answers][0][:id]}").click

    # choose an incorrect answer, so we get two arrows
    q = quiz.stored_questions[1]
    f("#question_#{q[:id]}_answer_#{q[:answers][1][:id]}").click

    f('#submit_quiz_button').click
    accept_alert # it will warn about having unanswered questions
    wait_for_ajaximations

    get "/courses/#{@course.id}/quizzes/#{quiz.id}/history?version=1"

    # all arrows should have an @id attribute node
    expect(ffj('.answer_arrow:not([id])').length).to eq 0

    # the following test cases are intermittent and broken:

    # there should be 5x <input /> nodes with an @aria-describedby attribute node
    expect(ffj('.answer input[aria-describedby]').length).to eq 5

    # this covers the fill-in-the-blank question edge case where the answers are
    # not input fields, so the @aria-describedby attribute is set on the wrapper
    # element instead
    expect(ffj('.answers_wrapper[aria-describedby]').length).to eq 1
  end
end
