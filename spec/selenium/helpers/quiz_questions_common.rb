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

require_relative "quizzes_common"

module QuizQuestionsCommon
  include QuizzesCommon

  def create_oqaat_quiz(opts={})
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
    @quiz = @course.quizzes.create
    quiz_question("Question 1", "What is the first question?", 1)
    quiz_question("Question 2", "What is the second question?", 2)
    @quiz.title = "OQAAT quiz"
    @quiz.one_question_at_a_time = true
    if opts[:publish]
      @quiz.publish!
      @quiz.generate_quiz_data
    end
    @quiz.save!
  end

  def quiz_question(name, question, _id)
    answers = [
      {:weight=>100, :answer_text=>"A", :answer_comments=>"", :id=>1490},
      {:weight=>0, :answer_text=>"B", :answer_comments=>"", :id=>1020},
      {:weight=>0, :answer_text=>"C", :answer_comments=>"", :id=>7051}
    ]
    data = { :question_name=>name, :points_possible=>1, :question_text=>question,
      :answers=>answers, :question_type=>"multiple_choice_question"
    }

    @quiz.quiz_questions.create!(:question_data => data)
  end

  def take_the_quiz
    open_quiz_show_page
    click_quiz_link("Take the Quiz")

    # sleep because display is updated on timer, not ajax callback
    sleep 1
  end

  def preview_the_quiz
    open_quiz_show_page
    f("#preview_quiz_button").click

    # sleep because display is updated on timer, not ajax callback
    sleep 1
  end

  def click_quiz_link(title)
    selector = "a:contains('#{title}')"
    wait = Selenium::WebDriver::Wait.new(timeout: 5)
    wait.until { !fj(selector).nil? }
    fj(selector).click
  end

  def navigate_away_and_resume_quiz
    open_quiz_show_page
    click_quiz_link("Resume Quiz")
  end

  def navigate_directly_to_first_question
    # defang the navigate-away-freakout-dialog
    driver.execute_script "window.onbeforeunload = function(){};"
    get course_quiz_question_path(:course_id => @course.id, :quiz_id => @quiz.id, :question_id => @quiz.quiz_questions.first.id)
    wait_for_ajaximations
  end

  def it_should_show_cant_go_back_warning
    expect(f('body')).to include_text \
      "Once you have submitted an answer, you will not be able to change it later"
  end

  def accept_cant_go_back_warning
    expect_new_page_load {
      fj("button:contains('Begin').ui-button").click
    }
    wait_for_ajaximations
  end

  def it_should_be_on_first_question
    it_should_be_on_question 'first question'
  end

  def it_should_be_on_second_question
    it_should_be_on_question 'second question'
  end

  def it_should_be_on_question(which_question)
    body = f('body')
    expect(body).to include_text which_question
    questions = ['first question', 'second question'] - [which_question]
    questions.each do |question|
      expect(body).not_to include_text question
    end
  end

  def it_should_have_sidebar_navigation
    expect_new_page_load {
      fj("#question_list a:contains('Question 2')").click
    }

    it_should_be_on_second_question

    expect_new_page_load {
      fj("#question_list a:contains('Question 1')").click
    }
    wait_for_ajaximations
    it_should_be_on_first_question
  end

  def click_next_button
    expect_new_page_load {
      f("button.next-question").click
    }
    wait_for_ajaximations
  end

  def click_previous_button
    expect_new_page_load {
      f("button.previous-question").click
    }
    wait_for_ajaximations
  end

  def it_should_show_previous_button
    expect(f("#content")).to contain_css("button.previous-question")
  end

  def it_should_not_show_previous_button
    expect(f("#content")).not_to contain_css("button.previous-question")
  end

  def it_should_show_next_button
    expect(f("#content")).to contain_css("button.next-question")
  end

  def it_should_not_show_next_button
    expect(f("#content")).not_to contain_css("button.next-question")
  end

  def submit_the_quiz
    f("#submit_quiz_button").click
  end

  def submit_unfinished_quiz(alert_message)
    submit_the_quiz

    expect(driver.switch_to.alert.text).to include alert_message

    driver.switch_to.alert.accept
    driver.switch_to.default_content
  end

  def click_next_button_and_accept_warning
    expect_new_page_load {
      f("button.next-question").click
      expect(driver.switch_to.alert.text).to include "leave it blank?"
      driver.switch_to.alert.accept
    }
  end

  def submit_finished_quiz
    submit_the_quiz
    expect(alert_present?).to be_falsey
  end

  def answer_the_question_correctly
    fj(".answers label:contains('A')").click
    wait_for_ajaximations
  end

  def answer_the_question_incorrectly
    fj(".answers label:contains('B')").click
    wait_for_ajaximations
  end

  def it_should_show_one_correct_answer
    expect(f('body')).to include_text "Score for this quiz: 1"
  end

  def back_and_forth_flow
    it_should_be_on_first_question
    it_should_not_show_previous_button
    it_should_show_next_button

    click_next_button
    it_should_be_on_second_question
    it_should_show_previous_button
    it_should_not_show_next_button
  end

  def check_if_cant_go_back
    it_should_be_on_first_question
    answer_the_question_correctly

    click_next_button
    it_should_be_on_second_question
    it_should_not_show_previous_button
  end

  def answers_flow
    answer_the_question_correctly
    click_next_button
    answer_the_question_incorrectly
    submit_finished_quiz
    it_should_show_one_correct_answer
  end
end
