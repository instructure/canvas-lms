require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes questions" do
  it_should_behave_like "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  context "as a teacher" do

    it "should edit a quiz question" do
      @context = @course
      q = quiz_model
      quest1 = q.quiz_questions.create!(:question_data => {:name => "first question"})
      q.generate_quiz_data
      q.save!
      get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
      wait_for_ajax_requests

      click_questions_tab
      hover_and_click(".edit_question_link")
      wait_for_animations
      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'Multiple Choice')
      replace_content(question.find_element(:css, 'input[name="question_name"]'), 'edited question')

      answers = question.find_elements(:css, ".form_answers > .answer")
      answers.length.should == 2
      question.find_element(:css, ".add_answer_link").click
      question.find_element(:css, ".add_answer_link").click
      answers = question.find_elements(:css, ".form_answers > .answer")
      answers.length.should == 4
      driver.action.move_to(answers[3]).perform
      answers[3].find_element(:css, ".delete_answer_link").click
      answers = question.find_elements(:css, ".form_answers > div.answer")
      answers.length.should == 3

      # check that the wiki sidebar is visible
      f('#editor_tabs .wiki-sidebar-header').should include_text("Insert Content into the Page")

      submit_form(question)
      question = f("#question_#{quest1.id}")
      question.find_element(:css, ".question_name").text.should == 'edited question'
      f('#show_question_details').click
      question.find_elements(:css, '.answers .answer').length.should == 3
    end

    it "should ignore html added in the quiz description" do
      bad_html = '<div id="question_16740547_question_text" class="question_text user_content enhanced">
                    <p>For Mead, what is the "essence" of the self?</p>
                  </div>
                  <div class="answers">
                    <div class="answers_wrapper">
                      <div id="answer_6949" class="answer answer_for_      correct_answer hover">&nbsp;</div>
                    </div>
                  </div>'

      quiz = start_quiz_question

      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'True/False')
      type_in_tiny '.question:visible textarea.question_content', bad_html
      submit_form(question)

      hover_and_click(".edit_question_link")
      ffj(".question_form:visible .form_answers .answer").size.should == 2
    end

    it "should not show Missing Word option in question types dropdown" do
      get "/courses/#{@course.id}/quizzes/new"

      ff("#question_form_template option.missing_word").length.should == 1

      click_questions_tab
      keep_trying_until {
        f(".add_question .add_question_link").click
        ff("#questions .question_holder").length > 0
      }
      ff("#questions .question_holder option.missing_word").length.should == 0
    end

    it "should reorder questions with drag and drop" do
      quiz_with_new_questions
      click_questions_tab

      # ensure they are in the right order
      names = ff('.question_name')
      names[0].text.should == 'first question'
      names[1].text.should == 'second question'

      load_simulate_js

      # drag the second question up 100px (next slot)
      driver.execute_script <<-JS
      $('.move_icon:eq(1)').show().simulate('drag', {dx: 0, dy: -100});
      JS

      # verify they were swapped
      names = ff('.question_name')
      names[0].text.should == 'second question'
      names[1].text.should == 'first question'
    end

    it "should not show the display details for text questions" do
      quiz = start_quiz_question

      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'Text (no question)')
      submit_form(question)
      wait_for_ajax_requests

      quiz.reload

      show_el = f('#show_question_details')
      show_el.should_not be_displayed
    end

    it "should not show the display details for essay questions" do
      quiz = start_quiz_question

      question = fj(".question_form:visible")
      click_option('.question_form:visible .question_type', 'Essay Question')
      submit_form(question)
      wait_for_ajax_requests

      quiz.reload

      show_el = f('#show_question_details')
      show_el.should_not be_displayed
    end

    it "should show the display details when questions other than text or essay questions exist" do
      quiz = start_quiz_question
      show_el = f('#show_question_details')
      question = fj(".question_form:visible")

      show_el.should_not be_displayed

      click_option('.question_form:visible .question_type', 'Multiple Choice')
      submit_form(question)
      wait_for_ajax_requests
      quiz.reload

      show_el.should be_displayed
    end

    it "should calculate correct quiz question points total" do
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
      quiz = Quiz.last
      quiz.reload
      quiz.quiz_questions.length.should == @question_count
    end

    it "should round published quiz points correctly on main quiz page" do
      pending("bug 7402 - Quiz points not rounding correctly") do
        q = @course.quizzes.create!(:title => "new quiz")
        75.times do
          q.quiz_questions.create!(:question_data => {:name => "Quiz Question 1", :question_type => 'essay_question', :question_text => 'qq1', 'answers' => [], :points_possible => 1.33})
        end
        q.generate_quiz_data
        q.workflow_state = 'available'
        q.save
        q.reload

        get "/courses/#{@course.id}/quizzes/#{Quiz.last.id}"
        fj('.summary td:eq(2)').text.should == "99.75%"
      end
    end

    it "should round numeric questions the same when created and taking a quiz" do
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
        wait_for_ajaximations
      end
      expect_new_page_load do
        f('.publish_quiz_button').click
        wait_for_ajaximations
      end
      expect_new_page_load do
        driver.find_element(:link, 'Take the Quiz').click
        wait_for_ajaximations
      end

      input = f('input[type=text]')
      input.click
      input.send_keys('0.000675')
      driver.execute_script <<-JS
      $('input[type=text]').trigger('change');
      JS
      expect_new_page_load {
        f('#submit_quiz_button').click
      }
      f('.score_value').text.strip.should == '1'
    end
  end

  context "select element behavior" do
    before (:each) do
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
                                 :assessment_question_id => nil
                             })
      q.generate_quiz_data
      q.save!
      get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
      f('.publish_quiz_button')
      get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@user.id}"
      driver.find_element(:link, 'Take the Quiz').click

      wait_for_ajax_requests
    end

    after do
      #This step is to prevent selenium from freezing when the dialog appears when leaving the page
      keep_trying_until do
        f('#left-side .quizzes').click
        confirm_dialog = driver.switch_to.alert
        confirm_dialog.accept
        true
      end
    end

    it "should selectmenu-ify select elements" do
      select = f('.question select')
      keep_trying_until { fj('.question_select:visible').should be_nil }

      f('.ui-selectmenu').click
      ff('.ui-selectmenu-open li')[1].click
      select[:selectedIndex].should == "1"
    end
  end
end
