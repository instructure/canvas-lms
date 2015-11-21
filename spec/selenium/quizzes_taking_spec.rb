require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quiz taking" do

  include_examples 'in-process server selenium tests'

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

  it "should show a prompt wehn attempting to submit with unanswered questions", priority: "1", test_id: 140608 do
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

  context "quiz with access code" do
     before :each do
       @quiz.access_code = "12345"
       @quiz.save!
       get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
       expect_new_page_load{f('#take_quiz_link').click}
     end

     it "should ask for access code for a quiz with access code restrictions", priority: "1", test_id: 345735 do
       expect(fj("input[type=password][name= 'access_code']")).to be_present
     end

     it "should not redirect to quiz taking page with incorrect access code", priority: "1", test_id: 338079 do
       expect(fj("input[type=password][name= 'access_code']")).to be_present
       fj("input[type=password][name= 'access_code']").send_keys('abcde')
       fj("button[type=submit]").click
       wait_for_ajaximations
       expect(fj("input[type=password][name= 'access_code']")).to be_present
     end

     it "should redirect to quiz taking page with correct access code", priority: "1", test_id: 345734 do
       expect(fj("input[type=password][name= 'access_code']")).to be_present
       fj("input[type=password][name= 'access_code']").send_keys('12345')
       fj("button[type=submit]").click
       wait_for_ajaximations
       expect(driver.current_url).to include_text("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
       expect(f("#content .quiz-header").text).to include('Test Quiz')
       expect(f('#submit_quiz_form')).to be_present
       # This is to prevent selenium from freezing when leaving the page
       fln('Quizzes').click
       driver.switch_to.alert.accept
     end
  end

  it "should restrict blacklisted ip addresses", priority: "1", test_id: 338081 do
    @quiz.ip_filter = "104.0.9.248"
    @quiz.save!
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    expect_new_page_load{f('#take_quiz_link').click}
    expect(f('#content').text).to include("This quiz is protected and is only available from certain locations."\
                " The computer you are currently using does not appear to be at a valid location for taking this quiz.")
    expect(f('#submit_quiz_form')).to be_nil
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