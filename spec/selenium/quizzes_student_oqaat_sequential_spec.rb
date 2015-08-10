require_relative 'helpers/quiz_questions_common'

describe 'One Question at a Time Quizzes as a student' do
  include_examples 'quiz question selenium tests'

  before(:each) do
    create_oqaat_quiz(publish: true)
    user_session(@student)
    @quiz.update_attribute(:cant_go_back, true)
  end

  it 'displays one question at a time but you can\'t go back',
  priority: "1", test_id: 209363 do
    take_the_quiz

    it_should_show_cant_go_back_warning
    accept_cant_go_back_warning

    check_if_cant_go_back
  end

  it 'saves answers and grades the quiz', priority: "1", test_id: 209364 do
    take_the_quiz
    it_should_show_cant_go_back_warning
    accept_cant_go_back_warning
    answers_flow
  end

  it 'doesn\'t allow cheating', priority: "1", test_id: 209365 do
    take_the_quiz
    accept_cant_go_back_warning

    click_next_button_and_accept_warning

    navigate_away_and_resume_quiz
    accept_cant_go_back_warning
    it_should_be_on_second_question

    navigate_directly_to_first_question
    it_should_be_on_second_question
  end

  it 'warns about submitting a quiz when not on the last question', priority: "1", test_id: 209366 do
    take_the_quiz
    accept_cant_go_back_warning
    answer_the_question_correctly

    submit_unfinished_quiz('There are still 2 questions you haven\'t seen')
  end

  it 'warns about moving on without answering the question', priority: "1", test_id: 209367 do
    take_the_quiz
    accept_cant_go_back_warning
    click_next_button_and_accept_warning
    submit_unfinished_quiz
  end

  it 'warns about resuming', priority: "1", test_id: 209368 do
    take_the_quiz

    it_should_show_cant_go_back_warning
    accept_cant_go_back_warning

    expect_new_page_load(true) do
      fj('a:contains(\'Quizzes\')').click
    end

    expect_new_page_load do
      fj('a:contains(\'OQAAT quiz\')').click
    end

    fj('#not_right_side .take_quiz_button a:contains(\'Resume Quiz\')').click

    it_should_show_cant_go_back_warning
    accept_cant_go_back_warning

    sequential_flow
  end
end