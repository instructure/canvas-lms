
require_relative "helpers/quiz_questions_common"

describe "One Question at a Time Quizzes as a student" do

  include_examples "quiz question selenium tests"

  before do
    create_oqaat_quiz(:publish => true)
    user_session(@student)
    @quiz.update_attribute(:cant_go_back, true)
  end

  it "displays one question at a time but you cant go back" do
    skip("193")
    take_the_quiz

    it_should_show_cant_go_back_warning
    accept_cant_go_back_warning

    sequential_flow
  end

  it "saves answers and grades the quiz" do
    take_the_quiz
    it_should_show_cant_go_back_warning
    accept_cant_go_back_warning
    answers_flow
  end

  it "doesnt allow you to cheat" do
    take_the_quiz
    accept_cant_go_back_warning

    click_next_button_and_accept_warning

    navigate_away_and_resume_quiz
    accept_cant_go_back_warning
    it_should_be_on_second_question
    
    navigate_directly_to_first_question
    it_should_be_on_second_question

    submit_unfinished_quiz
  end

  it "warns you about submitting a quiz when you are not on the last question" do
    take_the_quiz
    accept_cant_go_back_warning
    answer_the_question_correctly

    submit_unfinished_quiz("There are still 2 questions you haven't seen")
  end

  it "warns you about moving on when you havent answered the question" do
    take_the_quiz
    accept_cant_go_back_warning
    click_next_button_and_accept_warning
    submit_unfinished_quiz
  end

  it "should warn about resuming" do
    take_the_quiz

    it_should_show_cant_go_back_warning
    accept_cant_go_back_warning

    fj("a:contains('Quizzes')").click
    driver.switch_to.alert.accept

    wait_for_ajaximations

    fj("a:contains('OQAAT quiz')").click
    wait_for_ajaximations
    fj("#not_right_side .take_quiz_button a:contains('Resume Quiz')").click

    it_should_show_cant_go_back_warning
    accept_cant_go_back_warning

    sequential_flow
  end

end
