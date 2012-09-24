require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes" do
  it_should_behave_like "quizzes selenium tests"

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
      @course.update_attributes(:name => 'teacher course')
      @course.save!
      @course.reload
    end

    it "should allow a teacher to create a quiz from the quizzes tab directly" do
      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load { f(".new-quiz-link").click }
      submit_form("#quiz_options_form")
      wait_for_ajax_requests
      assert_flash_notice_message /Quiz data saved/
    end

    it "should create and preview a new quiz" do
      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load {
        f('.new-quiz-link').click
      }
      #check url
      driver.current_url.should match %r{/courses/\d+/quizzes/(\d+)\/edit}
      driver.current_url =~ %r{/courses/\d+/quizzes/(\d+)\/edit}
      quiz_id = $1.to_i
      quiz_id.should be > 0

      #input name and description then save quiz
      replace_content(ff('#quiz_title')[1], 'new quiz')
      test_text = "new description"
      keep_trying_until { f('#quiz_description_ifr').should be_displayed }
      type_in_tiny '#quiz_description', test_text
      in_frame "quiz_description_ifr" do
        f('#tinymce').should include_text(test_text)
      end

      #add a question
      f('.add_question_link').click
      submit_form('.question_form')
      wait_for_ajax_requests

      #save the quiz
      submit_form("#quiz_options_form")
      wait_for_ajax_requests

      #check quiz preview
      driver.find_element(:link, 'Preview the Quiz').click
      f('#questions').should be_present
    end

    it "should correctly hide form when cancelling quiz edit" do
      get "/courses/#{@course.id}/quizzes/new"

      wait_for_tiny f('#quiz_description')
      f(".add_question .add_question_link").click
      ff(".question_holder .question_form").length.should == 1
      f(".question_holder .question_form .cancel_link").click
      ff(".question_holder .question_form").length.should == 0
    end

    it "should pop up calendar on top of #main" do
      get "/courses/#{@course.id}/quizzes/new"
      f('#quiz_lock_at + .ui-datepicker-trigger').click
      cal = f('#ui-datepicker-div')
      cal.should be_displayed
      cal.style('z-index').should > f('#main').style('z-index')
    end

    it "should edit a quiz" do
      @context = @course
      q = quiz_model
      q.generate_quiz_data
      q.save!

      get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
      wait_for_ajax_requests

      test_text = "changed description"
      keep_trying_until { f('#quiz_description_ifr').should be_displayed }
      type_in_tiny '#quiz_description', test_text
      in_frame "quiz_description_ifr" do
        f('#tinymce').text.include?(test_text).should be_true
      end
      submit_form("#quiz_options_form")
      wait_for_ajax_requests

      get "/courses/#{@course.id}/quizzes/#{q.id}"

      f('#main .description').should include_text(test_text)
    end

    it "message students who... should do something" do
      @context = @course
      q = quiz_model
      q.generate_quiz_data
      q.save!
      # add a student to the course
      student = student_in_course(:active_enrollment => true).user
      student.conversations.size.should == 0

      get "/courses/#{@course.id}/quizzes/#{q.id}"

      driver.find_element(:partial_link_text, "Message Students Who...").click
      dialog = ffj("#message_students_dialog:visible")
      dialog.length.should == 1
      dialog = dialog.first

      click_option('.message_types', 'Have taken the quiz')
      students = ffj(".student_list > .student:visible")

      students.length.should == 0

      click_option('.message_types', 'Have NOT taken the quiz')
      students = ffj(".student_list > .student:visible")
      students.length.should == 1

      dialog.find_element(:css, 'textarea#body').send_keys('This is a test message.')

      submit_dialog(dialog)
      wait_for_ajax_requests

      student.conversations.size.should == 1
    end

    it "should not duplicate unpublished quizzes each time you open the publish multiple quizzes dialog" do
      5.times { @course.quizzes.create!(:title => "My Quiz") }
      get "/courses/#{@course.id}/quizzes"
      publish_multiple = f('.publish_multiple_quizzes_link')
      cancel = f('#publish_multiple_quizzes_dialog .cancel_button')

      5.times do
        publish_multiple.click
        ffj('#publish_multiple_quizzes_dialog .quiz_item:not(.blank)').length.should == 5
        cancel.click
      end
    end

    it "should create a new question group" do
      get "/courses/#{@course.id}/quizzes/new"

      f('.add_question_group_link').click
      group_form = f('#questions .quiz_group_form')
      group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
      replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '3')
      submit_form(group_form)
      group_form.find_element(:css, '.group_display.name').should include_text('new group')

    end

    it "should update a question group" do
      get "/courses/#{@course.id}/quizzes/new"

      f('.add_question_group_link').click
      group_form = f('#questions .quiz_group_form')
      group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
      replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '3')
      submit_form(group_form)
      group_form.find_element(:css, '.group_display.name').should include_text('new group')
      keep_trying_until { f("#quiz_display_points_possible .points_possible").text.should == "3" }

      group_form.find_element(:css, '.edit_group_link').click

      group_form.find_element(:name, 'quiz_group[name]').send_keys('renamed')
      replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '2')
      submit_form(group_form)
      group_form.find_element(:css, '.group_display.name').should include_text('renamed')
      keep_trying_until { f("#quiz_display_points_possible .points_possible").text.should == "2" }
    end

    it "should not let you exceed the question limit" do
      get "/courses/#{@course.id}/quizzes/new"

      f('.add_question_group_link').click
      group_form = f('#questions .quiz_group_form')
      pick_count_field = group_form.find_element(:name, 'quiz_group[pick_count]')
      pick_count = lambda do |count|
        driver.execute_script <<-JS
          var $pickCount = $('#questions .group_top input[name="quiz_group[pick_count]"]');
          $pickCount.focus();
          $pickCount[0].value = #{count.to_s.inspect};
          $pickCount.change();
        JS
      end

      pick_count.call('1001')
      dismiss_alert
      pick_count_field.should have_attribute(:value, "1")

      f('.add_question_link').click # 1 total, ok
      group_form.find_element(:css, '.edit_group_link').click
      pick_count.call('999') # 1000 total, ok

      f('.add_question_link').click # 1001 total, bad
      dismiss_alert

      pick_count.call('1000') # 1001 total, bad
      dismiss_alert
      pick_count_field.should have_attribute(:value, "999")
    end

    it "should moderate quiz" do
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      @context = @course
      q = quiz_model
      q.generate_quiz_data
      q.save!

      get "/courses/#{@course.id}/quizzes/#{q.id}/moderate"

      f('.moderate_student_link').click
      f('#extension_extra_attempts').send_keys('2')
      submit_form('#moderate_student_form')
      wait_for_ajax_requests
      f('.attempts_left').text.should == '3'

    end

    it "should flag a quiz question while taking a quiz as a teacher" do
      quiz_with_new_questions

      expect_new_page_load { f('.publish_quiz_button').click }
      wait_for_ajax_requests

      expect_new_page_load { driver.find_element(:link, 'Take the Quiz').click }

      #flag first question
      hover_and_click("#question_#{@quest1.id} .flag_question")

      #click second answer
      f("#question_#{@quest2.id} .answers .answer:first-child input").click
      submit_form('#submit_quiz_form')

      #dismiss dialog and submit quiz
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.dismiss
      f("#question_#{@quest1.id} .answers .answer:last-child input").click
      expect_new_page_load {
        submit_form('#submit_quiz_form')
      }
      f('#quiz_title').text.should == @q.title
    end

    it "should indicate when it was last saved" do
      take_quiz do
        indicator = f('#last_saved_indicator')
        indicator.text.should == 'Not saved'
        f('.answer .question_input').click

        # too fast, this always fails
        #indicator.text.should == 'Saving...'

        wait_for_ajax_requests
        indicator.text.should match(/^Saved at \d+:\d+(pm|am)$/)
      end
    end

    it "should validate numerical input data" do
      @quiz = quiz_with_new_questions do |bank, quiz|
        aq = AssessmentQuestion.create!
        bank.assessment_questions << aq
        quiz.quiz_questions.create!(:question_data => {:name => "numerical", 'question_type' => 'numerical_question', 'answers' => [], :points_possible => 1}, :assessment_question => aq)
      end
      take_quiz do
        input = f('.numerical_question_input')

        input.click
        input.send_keys('asdf')
        error_displayed?.should be_true
        input.send_keys(:tab)
        keep_trying_until { !error_displayed? }
        # gets cleared out since it's not valid
        input[:value].should be_blank

        input.click
        input.send_keys('1')
        error_displayed?.should be_false
        input.send_keys(:tab)
        input.should have_attribute(:value, "1.0000")
      end
    end

    it "should mark questions as answered when the window loses focus" do
      @quiz = quiz_with_new_questions do |bank, quiz|
        aq1 = AssessmentQuestion.create!
        aq2 = AssessmentQuestion.create!
        bank.assessment_questions << aq1
        bank.assessment_questions << aq2
        quiz.quiz_questions.create!(:question_data => {:name => "numerical", 'question_type' => 'numerical_question', 'answers' => [], :points_possible => 1}, :assessment_question => aq1)
        quiz.quiz_questions.create!(:question_data => {:name => "essay", 'question_type' => 'essay_question', 'answers' => [], :points_possible => 1}, :assessment_question => aq2)
      end
      take_quiz do
        wait_for_tiny f('.essay_question textarea.question_input')
        input = f('.numerical_question_input')
        input.click
        input.send_keys('1')
        in_frame f('.essay_question iframe')[:id] do
          f('#tinymce').send_keys :shift # no content, but it gives the iframe focus
        end
        wait_for_ajax_requests
        ff('#question_list .answered').size.should == 1
        input.should have_attribute(:value, "1.0000")
      end
    end

    it "should mark dropdown questions as answered" do
      @quiz = quiz_with_new_questions do |bank, quiz|
        aq1 = AssessmentQuestion.create!
        aq2 = AssessmentQuestion.create!
        bank.assessment_questions << aq1
        bank.assessment_questions << aq2
        q1 = quiz.quiz_questions.create!(:assessment_question => aq1)
        q1.write_attribute :question_data, {:name => "dropdowns", :question_type => 'multiple_dropdowns_question', :answers => [{:weight => 100, :text => "orange", :blank_id => "orange", :id => 1}, {:weight => 0, :text => "rellow", :blank_id => "orange", :id => 2}, {:weight => 100, :text => "green", :blank_id => "green", :id => 3}, {:weight => 0, :text => "yellue", :blank_id => "green", :id => 4}], :question_text => "<p>multiple answers red + yellow = [orange], yellow + blue = [green]</p>", :points_possible => 1}
        q1.save!
        q2 = quiz.quiz_questions.create!(:assessment_question => aq2)
        q2.write_attribute :question_data, {:name => "matching", :question_type => 'matching_question', :matches => [{:match_id => 1, :text => "north"}, {:match_id => 2, :text => "south"}, {:match_id => 3, :text => "east"}, {:match_id => 4, :text => "west"}], :answers => [{:left => "nord", :text => "nord", :right => "north", :match_id => 1}, {:left => "sud", :text => "sud", :right => "south", :match_id => 2}, {:left => "est", :text => "est", :right => "east", :match_id => 3}, {:left => "ouest", :text => "ouest", :right => "west", :match_id => 4}], :points_possible => 1}
        q2.save!
      end

      take_quiz do
        dropdowns = ff('a.ui-selectmenu.question_input')
        dropdowns.size.should == 6

        # partially answer each question
        [dropdowns.first, dropdowns.last].each do |d|
          d.click
          f('.ui-selectmenu-open li:nth-child(2)').click
        end
        # not marked as answered
        ff('#question_list .answered').should be_empty

        # fully answer each question
        dropdowns.each do |d|
          d.click
          f('.ui-selectmenu-open li:nth-child(2)').click
        end

        # marked as answer
        ff('#question_list .answered').size.should == 2
        wait_for_ajaximations

        driver.find_element(:link, 'Quizzes').click
        driver.switch_to.alert.accept
        wait_for_ajaximations

        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        driver.find_element(:link, "Resume Quiz").click
        # there's some initial setTimeout stuff that happens, so things won't
        # be ready right when the page loads
        keep_trying_until {
          dropdowns = ff('a.ui-selectmenu.question_input')
          dropdowns.size.should == 6
        }

        dropdowns.map(&:text).should == %w{orange green east east east east}
        ff('#question_list .answered').size.should == 2
      end
    end

    it "should give a student extra time if the time limit is extended" do
      @context = @course
      bank = @course.assessment_question_banks.create!(:title => 'Test Bank')
      q = quiz_model
      a = AssessmentQuestion.create!
      b = AssessmentQuestion.create!
      bank.assessment_questions << a
      bank.assessment_questions << b
      answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
      question = q.quiz_questions.create!(:question_data => {
          :name => "first question",
          'question_type' => 'multiple_choice_question',
          'answers' => answers,
          :points_possible => 1
      }, :assessment_question => a)

      q.generate_quiz_data
      q.time_limit = 10
      q.save!

      get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@user.id}"
      driver.find_element(:link_text, 'Take the Quiz').click

      answer_one = f("#question_#{question.id}_answer_1")
      answer_two = f("#question_#{question.id}_answer_2")

      # force a save to create a submission
      answer_one.click
      wait_for_ajax_requests

      # increase the time limit on the quiz
      q.update_attribute(:time_limit, 20)
      q.update_quiz_submission_end_at_times

      keep_trying_until do
        assert_flash_notice_message /You have been given extra time on this attempt/
        f('.time_running').text.should match /^[19]{2}\sMinutes/
      end

      #This step is to prevent selenium from freezing when the dialog appears when leaving the page
      driver.find_element(:link, I18n.t('links_to.quizzes', 'Quizzes')).click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
    end

    it "should notify a student of extra time given by a moderator" do
      @context = @course
      bank = @course.assessment_question_banks.create!(:title => 'Test Bank')
      q = quiz_model
      a = AssessmentQuestion.create!
      b = AssessmentQuestion.create!
      bank.assessment_questions << a
      bank.assessment_questions << b
      answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
      question = q.quiz_questions.create!(:question_data => {
          :name => "first question",
          'question_type' => 'multiple_choice_question',
          'answers' => answers,
          :points_possible => 1
      }, :assessment_question => a)

      q.generate_quiz_data
      q.time_limit = 10
      q.save!

      get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@user.id}"
      driver.find_element(:link_text, 'Take the Quiz').click

      answer_one = f("#question_#{question.id}_answer_1")
      answer_two = f("#question_#{question.id}_answer_2")

      # force a save to create a submission
      answer_one.click
      wait_for_ajax_requests

      # add time as a the moderator. this code replicates what happens in
      # QuizSubmissions#extensions when a moderator extends a student's
      # quiz time.
      submission = QuizSubmission.last
      submission.end_at = Time.now + 20.minutes
      submission.save!

      keep_trying_until do
        assert_flash_notice_message /You have been given extra time on this attempt/
        f('.time_running').text.should match /^[19]{2}\sMinutes/
        true
      end

      #This step is to prevent selenium from freezing when the dialog appears when leaving the page
      driver.find_element(:link, I18n.t('links_to.quizzes', 'Quizzes')).click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
    end


    it "should display quiz statistics" do
      quiz_with_submission
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      driver.find_element(:link, "Quiz Statistics").click

      f('#content .question_name').should include_text("Question 1")
    end
  end
end

