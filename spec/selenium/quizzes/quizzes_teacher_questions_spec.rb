require_relative '../common'
require_relative '../helpers/quizzes_common'

describe "quizzes questions" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before(:each) do
    course_with_teacher_logged_in
    @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
    @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')
  end

  context "as a teacher" do

    it "should edit a quiz question", priority: "1", test_id: 209946 do
      @context = @course
      q = quiz_model
      quest1 = q.quiz_questions.create!(:question_data => {:name => "first question"})
      q.generate_quiz_data
      q.save!
      get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
      wait_for_ajax_requests

      click_questions_tab
      wait_for_ajaximations
      hover_and_click(".edit_question_link")
      wait_for_ajaximations
      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'Multiple Choice')
      replace_content(question.find_element(:css, 'input[name="question_name"]'), 'edited question')

      answers = question.find_elements(:css, ".form_answers > .answer")
      expect(answers.length).to eq 2
      question.find_element(:css, ".add_answer_link").click
      question.find_element(:css, ".add_answer_link").click
      answers = question.find_elements(:css, ".form_answers > .answer")
      expect(answers.length).to eq 4
      driver.action.move_to(answers[3]).perform
      answers[3].find_element(:css, ".delete_answer_link").click
      answers = question.find_elements(:css, ".form_answers > div.answer")
      expect(answers.length).to eq 3

      # check that the wiki sidebar is visible
      expect(f('#editor_tabs .wiki-sidebar-header')).to include_text("Insert Content into the Page")

      submit_form(question)
      question = f("#question_#{quest1.id}")
      expect(question.find_element(:css, ".question_name")).to include_text('edited question')
      f('#show_question_details').click
      expect(question.find_elements(:css, '.answers .answer').length).to eq 3
    end

    it "should sanitize any html added to the quiz question description", priority: "1", test_id: 209947 do
      bad_html = '<div id="question_16740547_question_text" class="question_text user_content enhanced">
                    <p>For Mead, what is the "essence" of the self?</p>
                  </div>
                  <div class="answers">
                    <div class="answers_wrapper">
                      <div id="answer_6949" class="answer answer_for_      correct_answer hover">&nbsp;</div>
                    </div>
                  </div>'

      start_quiz_question

      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'True/False')
      type_in_tiny '.question:visible textarea.question_content', bad_html
      submit_form(question)

      hover_and_click(".edit_question_link")

      # verify that the HTML added to the description didn't effectively create a third possible answer
      expect(ffj(".question_form:visible .form_answers .answer").size).to eq 2
    end

    it "should not show Missing Word option in question types dropdown", priority: "1", test_id: 209948 do
      get "/courses/#{@course.id}/quizzes/new"

      expect(ff("#question_form_template option.missing_word").length).to eq 1

      click_questions_tab
      f(".add_question .add_question_link").click
      expect(f("#questions")).not_to contain_css(".question_holder option.missing_word")
    end

    it "should not show the display details for text questions", priority: "1", test_id: 209951 do
      quiz = start_quiz_question

      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'Text (no question)')
      submit_form(question)
      wait_for_ajax_requests

      quiz.reload

      show_el = f('#show_question_details')
      expect(show_el).not_to be_displayed
    end

    it "should not show the display details for essay questions", priority: "1", test_id: 209950 do
      quiz = start_quiz_question

      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'Essay Question')
      submit_form(question)
      wait_for_ajax_requests

      quiz.reload

      show_el = f('#show_question_details')
      expect(show_el).not_to be_displayed
    end

    it "should show the display details when questions other than text or essay questions exist", priority: "1", test_id: 209952 do
      quiz = start_quiz_question
      show_el = f('#show_question_details')
      question = fj(".question_form:visible")

      expect(show_el).not_to be_displayed

      click_option('.question_form:visible .question_type', 'Multiple Choice')
      submit_form(question)
      wait_for_ajax_requests
      quiz.reload

      expect(show_el).to be_displayed
    end

    it "should calculate correct quiz question points total", priority: "1", test_id: 209953 do
      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load { f('.new-quiz-link').click }
      @question_count = 0
      @points_total = 0

      add_quiz_question('1')
      add_quiz_question('2')
      add_quiz_question('3')
      add_quiz_question('4')

      click_save_settings_button
      wait_for_ajax_requests
      quiz = Quizzes::Quiz.last
      quiz.reload
      expect(quiz.quiz_questions.length).to eq @question_count
    end

    it "should round published quiz points correctly on main quiz page", priority: "2", test_id: 209954 do
      skip("bug 7402 - Quiz points not rounding correctly")
      q = @course.quizzes.create!(:title => "new quiz")
      75.times do
        q.quiz_questions.create!(:question_data => {:name => "Quiz Question 1", :question_type => 'essay_question', :question_text => 'qq1', 'answers' => [], :points_possible => 1.33})
      end
      q.generate_quiz_data
      q.workflow_state = 'available'
      q.save
      q.reload

      get "/courses/#{@course.id}/quizzes/#{Quizzes::Quiz.last.id}"
      expect(fj('.summary td:eq(2)').text).to eq "99.75%"
    end

    it "should round numeric questions the same when created and taking a quiz", priority: "1", test_id: 209955 do
      start_quiz_question
      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'Numerical Answer')
      wait_for_ajaximations

      type_in_tiny '.question:visible textarea.question_content', 'This is a numerical question.'

      answers = question.find_elements(:css, ".form_answers > .answer")
      answers[0].find_element(:name, 'answer_exact').send_keys('0.000675')
      driver.execute_script <<-JS
      $('input[name=answer_exact]').trigger('change');
      JS
      answers[0].find_element(:name, 'answer_error_margin').send_keys('0')
      submit_form(question)
      wait_for_ajaximations

      expect_new_page_load do
        f('.save_quiz_button').click
      end

      user_session(@student)
      get "/courses/#{@course.id}/quizzes/#{Quizzes::Quiz.last.id}"

      expect_new_page_load do
        f("#take_quiz_link").click
        wait_for_ajaximations
      end

      input = f('input[type=text]')
      input.click
      input.send_keys('0.000675')
      driver.execute_script <<-JS
      $('input[type=text]').trigger('change');
      JS
      expect_new_page_load { f('#submit_quiz_button').click }
      expect(f('.score_value').text.strip).to eq '1'
      user_session(@user)
    end
  end

  context "select element behavior" do
    before(:each) do
      @context = @course
      bank = @course.assessment_question_banks.create!(:title => 'Test Bank')
      q = quiz_model
      b = bank.assessment_questions.create!
      quest2 = q.quiz_questions.create!(:assessment_question => b)
      quest2.write_attribute(:question_data,
                             {
                                 :neutral_comments => "",
                                 :question_text => "<p>My hair is [x] and my wife's is [y].</p>",
                                 :points_possible => 1, :question_type => "multiple_dropdowns_question",
                                 :answers =>
                                     [{
                                          :comments => "",
                                          :weight => 100,
                                          :blank_id => "x",
                                          :text => "brown",
                                          :id => 2624
                                      },
                                      {
                                          :comments => "",
                                          :weight => 0,
                                          :blank_id => "x",
                                          :text => "black",
                                          :id => 3085
                                      },
                                      {
                                          :comments => "",
                                          :weight => 100,
                                          :blank_id => "y",
                                          :text => "brown",
                                          :id => 5780
                                      },
                                      {
                                          :comments => "",
                                          :weight => 0,
                                          :blank_id => "y",
                                          :text => "red",
                                          :id => 8840
                                      }],
                                 :correct_comments => "",
                                 :name => "Question",
                                 :question_name => "Question",
                                 :incorrect_comments => "",
                                 :assessment_question_id => b.id
                             })
      quest2.save!
      q.generate_quiz_data
      q.save!
      get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
      f('.quiz-publish-button')
      get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@user.id}"
      f("#take_quiz_link").click

      wait_for_ajax_requests
    end
  end
end
