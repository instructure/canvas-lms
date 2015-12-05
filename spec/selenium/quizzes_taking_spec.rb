require_relative "common"
require_relative "helpers/quizzes_common"

describe "quiz taking" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before :each do
    course_with_student_logged_in(:active_all => true)
    @quiz = quiz_with_new_questions(!:goto_edit)
  end

  it "should allow to take the quiz as long as there are attempts left", priority: "1", test_id: 140606 do
    @quiz.allowed_attempts = 2
    @quiz.save!
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load{f('#take_quiz_link').click}
    answer_questions_and_submit(@quiz, 2)
    expect(f('#take_quiz_link')).to be_present
    expect_new_page_load{f('#take_quiz_link').click}
    answer_questions_and_submit(@quiz, 2)
    expect(f('#take_quiz_link')).to be_nil
  end

  it "should show a prompt when attempting to submit with unanswered questions", priority: "1", test_id: 140608 do
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load{f('#take_quiz_link').click}
    # answer just one question
    question = @quiz.stored_questions[0][:id]
    fj("input[type=radio][name= 'question_#{question}']").click
    wait_for_js
    f('#submit_quiz_button').click
    # expect alert prompt to show, dismiss and answer the remaining questions
    expect(driver.switch_to.alert.text).to be_present
    dismiss_alert
    question = @quiz.stored_questions[1][:id]
    fj("input[type=radio][name= 'question_#{question}']").click
    wait_for_js
    expect_new_page_load { f('#submit_quiz_button').click }
    keep_trying_until do
      expect(f('.quiz-submission .quiz_score .score_value')).to be_displayed
    end
  end

  it "should not restrict whitelisted ip addresses", priority: "1", test_id: 338082 do
    skip('might fail Jenkins due to ip address conflicts')
    @quiz.ip_filter = "10.0.9.249"
    @quiz.save!
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load{f('#take_quiz_link').click}
    expect(driver.current_url).to include_text("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    expect(f("#content .quiz-header").text).to include('Test Quiz')
    expect(f('#submit_quiz_form')).to be_present
  end
end