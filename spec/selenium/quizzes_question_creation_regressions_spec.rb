require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes question creation edge cases" do

  include_examples "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
  end

  it "should create a quiz with a variety of quiz questions" do
    quiz = @last_quiz

    click_questions_tab
    create_multiple_choice_question
    click_new_question_button
    create_true_false_question
    click_new_question_button
    create_fill_in_the_blank_question

    quiz.reload
    refresh_page #making sure the quizzes load up from the database
    click_questions_tab
    3.times do |i|
      keep_trying_until(100) {expect(f("#question_#{quiz.quiz_questions[i].id}")).to be_displayed}
    end
    questions = ff('.display_question')
    expect(questions[0]).to have_class("multiple_choice_question")
    expect(questions[1]).to have_class("true_false_question")
    expect(questions[2]).to have_class("short_answer_question")
  end

  it "should not create an extra, blank, correct answer when you use [answer] as a placeholder" do
    quiz = @last_quiz

    # be a multiple dropdown question
    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Multiple Dropdowns')

    # set up a placeholder (this is the bug)
    type_in_tiny '.question:visible textarea.question_content', 'What is the [answer]'

    # check answer select
    select_box = question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    expect(options[0].text).to eq 'answer'

    # input answers for the blank input
    answers = question.find_elements(:css, ".form_answers > .answer")
    answers[0].find_element(:css, ".select_answer_link").click

    # make up some answers
    replace_content(answers[0].find_element(:css, '.select_answer input'), 'a')
    replace_content(answers[1].find_element(:css, '.select_answer input'), 'b')

    # save the question
    submit_form(question)
    wait_for_ajax_requests

    # check to see if the questions displays correctly
    f('#show_question_details').click
    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    expect(finished_question).to be_displayed

    # check to make sure extra answers were not generated
    expect(quiz.quiz_questions.first.question_data["answers"].count).to eq 2
    expect(quiz.quiz_questions.first.question_data["answers"].detect{|a| a["text"] == ""}).to be_nil
  end

  it "respects character limits on short answer questions" do
    quiz = @last_quiz
    question = fj(".question_form:visible")
    click_option('.question_form:visible .question_type', 'Fill In the Blank')

    replace_content(question.find_element(:css, "input[name='question_points']"), '4')

    answers = question.find_elements(:css, ".form_answers > .answer")
    answer = answers[0].find_element(:css, ".short_answer input")

    short_answer_field = lambda {
      replace_content(answer, 'a'*100)
      driver.execute_script(%{$('.short_answer input:focus').blur();}) unless alert_present?
    }

    keep_trying_until do
      short_answer_field.call
      alert_present?
    end
    alert = driver.switch_to.alert
    expect(alert.text).to match /Answers for fill in the blank questions must be under 80 characters long/
    alert.dismiss
  end

  it "should show errors for graded quizzes but not surveys" do
    quiz_with_new_questions
    change_quiz_type_to 'Graded Survey'
    expect_new_page_load {
      save_settings
      wait_for_ajax_requests
    }

    edit_quiz
    click_questions_tab
    edit_and_save_first_multiple_choice_answer 'instructure!'
    expect(error_displayed?).to be_falsey

    refresh_page
    click_questions_tab
    edit_and_save_first_multiple_choice_answer 'yog!'

    click_settings_tab
    change_quiz_type_to 'Graded Quiz'
    expect_new_page_load {
      save_settings
      wait_for_ajax_requests
    }

    edit_quiz
    click_questions_tab
    edit_first_question
    delete_first_multiple_choice_answer
    save_question
    expect(error_displayed?).to be_truthy

    refresh_page
    click_questions_tab
    edit_first_question
    delete_first_multiple_choice_answer
    save_question
    expect(error_displayed?).to be_truthy
  end
end
