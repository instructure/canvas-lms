require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes" do

  include AssignmentOverridesSeleniumHelper
  include_examples "quizzes selenium tests"

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
      @course.update_attributes(:name => 'teacher course')
      @course.save!
      @course.reload
    end

    it "should show a summary of due dates if there are multiple" do
      create_quiz_with_default_due_dates
      get "/courses/#{@course.id}/quizzes"
      expect(f('.item-group-container .date-available')).not_to include_text "Multiple Dates"
      add_due_date_override(@quiz)

      get "/courses/#{@course.id}/quizzes"
      expect(f('.item-group-container .date-available')).to include_text "Multiple Dates"
      driver.mouse.move_to f('.item-group-container .date-available')
      wait_for_ajaximations
      tooltip = fj('.ui-tooltip:visible')
      expect(tooltip).to include_text 'New Section'
      expect(tooltip).to include_text 'Everyone else'
    end

    it "should allow a teacher to create a quiz from the quizzes tab directly" do
      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load { f(".new-quiz-link").click }
      expect_new_page_load do
        click_save_settings_button
        wait_for_ajax_requests
      end
      expect(f('#quiz_title')).to include_text "Unnamed Quiz"
    end

    it "should create and preview a new quiz" do
      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load do
        f('.new-quiz-link').click
        wait_for_ajaximations
      end
      #check url
      expect(driver.current_url).to match %r{/courses/\d+/quizzes/(\d+)\/edit}
      driver.current_url =~ %r{/courses/\d+/quizzes/(\d+)\/edit}
      quiz_id = $1.to_i
      expect(quiz_id).to be > 0

      #input name and description then save quiz
      replace_content(f('#quiz_title'), 'new quiz')
      test_text = "new description"
      keep_trying_until { expect(f('#quiz_description_ifr')).to be_displayed }
      type_in_tiny '#quiz_description', test_text
      in_frame "quiz_description_ifr" do
        expect(f('#tinymce')).to include_text(test_text)
      end

      #add a question
      click_questions_tab
      click_new_question_button
      submit_form('.question_form')
      wait_for_ajaximations

      #save the quiz
      expect_new_page_load {
        click_save_settings_button
        wait_for_ajaximations
      }
      wait_for_ajaximations

      #check quiz preview
      f('#preview_quiz_button').click
      expect(f('#questions')).to be_present
    end

    it "should edit a quiz" do
      @context = @course
      q = quiz_model
      q.generate_quiz_data
      q.save!

      get "/courses/#{@course.id}/quizzes/#{q.id}/edit"
      wait_for_ajaximations

      test_text = "changed description"
      keep_trying_until { expect(f('#quiz_description_ifr')).to be_displayed }
      type_in_tiny '#quiz_description', test_text
      in_frame "quiz_description_ifr" do
        expect(f('#tinymce')).to include_text(test_text)
      end
      click_save_settings_button
      wait_for_ajaximations

      get "/courses/#{@course.id}/quizzes/#{q.id}"

      expect(f('#main .description')).to include_text(test_text)
    end

    it "should asynchronously load student quiz results" do
      @context = @course
      q = quiz_model
      q.generate_quiz_data
      q.save!

      get "/courses/#{@course.id}/quizzes/#{q.id}"
      f('.al-trigger').click
      f('.quiz_details_link').click
      wait_for_ajaximations
      expect(f('#quiz_details')).to be_displayed
    end

    
    it "should republish on save" do
      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load { f(".new-quiz-link").click }
      quiz = Quizzes::Quiz.last
      expect_new_page_load do
        click_save_settings_button
        wait_for_ajax_requests
      end

      # Hides SpeedGrader link when unpublished
      expect(f('.icon-speed-grader')).to be_nil

      expect(f('#quiz-publish-link')).not_to include_text("Published")
      expect(f('#quiz-publish-link')).to include_text("Publish")

      expect(quiz.versions.length).to eq 1
      f('#quiz-publish-link').click
      wait_for_ajax_requests
      quiz.reload
      expect(quiz.versions.length).to eq 2
      get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
      expect_new_page_load {
        expect(f('#quiz-draft-state').text.strip).to match accessible_variant_of 'Published'
        expect_new_page_load do
          click_save_settings_button
          wait_for_ajax_requests
        end
      }
      quiz.reload
      expect(quiz.versions.length).to eq 3

      # Shows speedgrader when published
      expect(f('.icon-speed-grader')).not_to be_nil
    end

    it "should create a new question group" do
      get "/courses/#{@course.id}/quizzes/new"

      click_questions_tab
      f('.add_question_group_link').click
      group_form = f('#questions .quiz_group_form')
      group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
      replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '3')
      submit_form(group_form)
      expect(group_form.find_element(:css, '.group_display.name')).to include_text('new group')

    end

    it "should update a question group" do
      get "/courses/#{@course.id}/quizzes/new"

      click_questions_tab
      f('.add_question_group_link').click
      group_form = f('#questions .quiz_group_form')
      group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
      replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '3')
      submit_form(group_form)
      expect(group_form.find_element(:css, '.group_display.name')).to include_text('new group')
      click_settings_tab
      keep_trying_until { expect(f("#quiz_display_points_possible .points_possible").text).to eq "3" }

      click_questions_tab
      group_form.find_element(:css, '.edit_group_link').click

      group_form.find_element(:name, 'quiz_group[name]').send_keys('renamed')
      replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '2')
      submit_form(group_form)
      expect(group_form.find_element(:css, '.group_display.name')).to include_text('renamed')
      click_settings_tab
      keep_trying_until { expect(f("#quiz_display_points_possible .points_possible").text).to eq "2" }
    end

    it "should not let you exceed the question limit" do
      get "/courses/#{@course.id}/quizzes/new"

      click_questions_tab
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
      expect(pick_count_field).to have_attribute(:value, "1")

      click_new_question_button # 1 total, ok
      group_form.find_element(:css, '.edit_group_link').click
      pick_count.call('999') # 1000 total, ok

      click_new_question_button # 1001 total, bad
      dismiss_alert

      pick_count.call('1000') # 1001 total, bad
      dismiss_alert
      expect(pick_count_field).to have_attribute(:value, "999")
    end

    it "should moderate quiz" do
      student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
      @context = @course
      q = quiz_model
      q.time_limit = 20
      q.generate_quiz_data
      q.save!

      get "/courses/#{@course.id}/quizzes/#{q.id}/moderate"
      f('.moderate_student_link').click

      # validates data
      f('#extension_extra_attempts').send_keys('asdf')
      submit_form('#moderate_student_form')
      expect(f('.attempts_left').text).to eq '1'

      # valid values
      f('#extension_extra_attempts').clear()
      f('#extension_extra_attempts').send_keys('2')
      submit_form('#moderate_student_form')
      wait_for_ajax_requests
      expect(f('.attempts_left').text).to eq '3'
    end

    
    it "should indicate when it was last saved" do
      take_quiz do
        indicator = f('#last_saved_indicator')
        expect(indicator.text).to eq 'Not saved'
        f('.answer .question_input').click

        # too fast, this always fails
        #indicator.text.should == 'Saving...'

        wait_for_ajax_requests
        expect(indicator.text).to match(/^Quiz saved at \d+:\d+(pm|am)$/)
      end
    end

    it "should validate numerical input data" do
      @quiz = quiz_with_new_questions do |bank, quiz|
        aq = bank.assessment_questions.create!
        quiz.quiz_questions.create!(:question_data => {:name => "numerical", 'question_type' => 'numerical_question', 'answers' => [], :points_possible => 1}, :assessment_question => aq)
      end
      take_quiz do
        input = f('.numerical_question_input')

        input.click
        input.send_keys('asdf')
        wait_for_ajaximations
        expect(error_displayed?).to be_truthy
        input.send_keys(:tab)
        wait_for_ajaximations
        keep_trying_until {
          expect(input[:value]).to be_blank  
        }

        input.click
        input.send_keys('1')
        wait_for_ajaximations
        expect(error_displayed?).to be_falsey
        input.send_keys(:tab)
        wait_for_ajaximations
        keep_trying_until {
          expect(input).to have_attribute(:value, "1.0000")
        }
      end
    end

    it "should mark dropdown questions as answered" do
      skip("xvfb issues")
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
        dropdowns = ffj('a.ui-selectmenu.question_input')
        expect(dropdowns.size).to eq 6

        # partially answer each question
        [dropdowns.first, dropdowns.last].each do |d|
          d.click
          wait_for_ajaximations
          f('.ui-selectmenu-open li:nth-child(2)').click
          wait_for_ajaximations
        end
        # not marked as answered
        keep_trying_until {
          expect(ff('#question_list .answered')).to be_empty
        }

        # fully answer each question
        dropdowns.each do |d|
          d.click
          wait_for_ajaximations
          f('.ui-selectmenu-open li:nth-child(2)').click
          wait_for_ajaximations
        end

        # marked as answer
        keep_trying_until {
          expect(ff('#question_list .answered').size).to eq 2 
        }
        wait_for_ajaximations

        driver.find_element(:link, 'Quizzes').click
        wait_for_ajaximations

        driver.switch_to.alert.accept
        wait_for_ajaximations

        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        f(:link, "Resume Quiz").click

        # there's some initial setTimeout stuff that happens, so things won't
        # be ready right when the page loads
        keep_trying_until {
          dropdowns = ff('a.ui-selectmenu.question_input')
          expect(dropdowns.size).to eq 6
          expect(dropdowns.map(&:text)).to eq %w{orange green east east east east}
        }
        expect(ff('#question_list .answered').size).to eq 2
      end
    end

    it "should give a student extra time if the time limit is extended" do
      @context = @course
      bank = @course.assessment_question_banks.create!(:title => 'Test Bank')
      q = quiz_model
      a = bank.assessment_questions.create!
      b = bank.assessment_questions.create!
      answers = [{id: 1, answer_text: 'A', weight: 100}, {id: 2, answer_text: 'B', weight: 0}]
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
      f("#take_quiz_link").click

      answer_one = f("#question_#{question.id}_answer_1")
      answer_two = f("#question_#{question.id}_answer_2")

      # force a save to create a submission
      answer_one.click
      wait_for_ajaximations

      # add time as a the moderator. this code replicates what happens in
      # QuizSubmissions#extensions when a moderator extends a student's
      # quiz time.

      quiz_original_end_time = Quizzes::QuizSubmission.last.end_at
      keep_trying_until do
        submission = Quizzes::QuizSubmission.last
        submission.end_at = Time.now + 20.minutes
        submission.save!
        quiz_original_end_time < Quizzes::QuizSubmission.last.end_at
        expect(f('.time_running').text).to match /19 Minutes/
      end
    end

    def upload_attachment_answer
      fj('input[type=file]').send_keys @fullpath
      wait_for_ajaximations
      keep_trying_until do
        fj('.file-uploaded').text
        fj('.list_question, .answered').text
      end
      fj('.upload-label').click
      wait_for_ajaximations
    end

    def file_upload_submission_data
      @quiz.reload.quiz_submissions.first.
          submission_data["question_#{@question.id}".to_sym]
    end

    def file_upload_attachment
      @quiz.reload.quiz_submissions.first.attachments.first
    end


    it "works with file upload questions" do
      @context = @course
      bank = @course.assessment_question_banks.create!(:title => 'Test Bank')
      q = quiz_model
      a = bank.assessment_questions.create!
      b = bank.assessment_questions.create!
      answers = {'answer_0' => {'id' => 1}, 'answer_1' => {'id' => 2}}
      @question = q.quiz_questions.create!(:question_data => {
          :name => "first question",
          'question_type' => 'file_upload_question',
          'question_text' => 'file upload question maaaan',
          'answers' => answers,
          :points_possible => 1
      }, :assessment_question => a)
      q.generate_quiz_data
      q.save!
      filename, @fullpath, data = get_file "testfile1.txt"
      get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@user.id}"
      expect_new_page_load do
        f("#take_quiz_link").click
      end
      wait_for_ajaximations
      # so we can .send_keys to the input, can't if it's invisible to
      # the browser
      driver.execute_script "$('.file-upload').removeClass('hidden')"
      upload_attachment_answer
      expect(file_upload_submission_data).to eq [file_upload_attachment.id.to_s]
      # delete the attachment id
      fj('.delete-attachment').click
      keep_trying_until do
        expect(fj('.answered')).to eq nil
      end

      fj('.upload-label').click
      wait_for_ajaximations
      keep_trying_until do
        expect(file_upload_submission_data).to eq [""]
      end
      upload_attachment_answer
      expect_new_page_load do
        driver.get driver.current_url
        driver.switch_to.alert.accept
      end
      wait_for_ajaximations
      attachment = file_upload_attachment
      expect(fj('.file-upload-box').text).to include attachment.display_name
      f('#submit_quiz_button').click
      wait_for_ajaximations
      keep_trying_until do
        expect(fj('.selected_answer').text).to include attachment.display_name
      end
    end

    it "should notify a student of extra time given by a moderator" do
      skip('broken')
      @context = @course
      bank = @course.assessment_question_banks.create!(:title => 'Test Bank')
      q = quiz_model
      a = bank.assessment_questions.create!
      b = bank.assessment_questions.create!
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
      f("#take_quiz_link").click

      answer_one = f("#question_#{question.id}_answer_1")
      answer_two = f("#question_#{question.id}_answer_2")

      # force a save to create a submission
      answer_one.click
      wait_for_ajaximations

      # add time as a the moderator. this code replicates what happens in
      # QuizSubmissions#extensions when a moderator extends a student's
      # quiz time.


      quiz_original_end_time = Quizzes::QuizSubmission.last.end_at


      submission = Quizzes::QuizSubmission.last
      submission.end_at = Time.now + 20.minutes
      submission.save!
      quiz_original_end_time < Quizzes::QuizSubmission.last.end_at
      assert_flash_notice_message /You have been given extra time on this attempt/
      expect(f('.time_running').text).to match /19 Minutes/
    end


    it "should display quiz statistics" do
      quiz_with_submission
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      click_quiz_statistics_button

      expect(f('#content .question_name')).to include_text("Question 1")
    end

    it "should display a link to quiz statistics for a MOOC" do
      quiz_with_submission
      @course.large_roster = true
      @course.save!
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      expect(f('#right-side')).to include_text('Quiz Statistics')
    end

    it "should delete a quiz" do
      quiz_with_submission
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      expect_new_page_load do
        f('.al-trigger').click
        f('.delete_quiz_link').click
        accept_alert
      end

      # Confirm that we make it back to the quizzes index page
      expect(f('#content')).to include_text("Course Quizzes")
      expect(@quiz.reload).to be_deleted
    end

    it "can create overrides" do
      @quiz = create_quiz_with_default_due_dates
      default_section = @course.course_sections.first
      other_section = @course.course_sections.create!(:name => "other section")
      default_section_due = Time.zone.now + 1.days
      other_section_due = Time.zone.now + 2.days
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      wait_for_ajaximations
      select_first_override_section(default_section.name)
      first_due_at_element.clear
      first_due_at_element.
          send_keys(default_section_due.strftime('%b %-d, %y'))

      add_override

      select_last_override_section(other_section.name)
      last_due_at_element.
          send_keys(other_section_due.strftime('%b %-d, %y'))
      expect_new_page_load do
        click_save_settings_button
        wait_for_ajax_requests
      end
      overrides = @quiz.reload.assignment_overrides
      expect(overrides.size).to eq 2
      default_override = overrides.detect { |o| o.set_id == default_section.id }
      expect(default_override.due_at.strftime('%b %-d, %y')).
          to eq default_section_due.to_date.strftime('%b %-d, %y')
      other_override = overrides.detect { |o| o.set_id == other_section.id }
      expect(other_override.due_at.strftime('%b %-d, %y')).
          to eq other_section_due.to_date.strftime('%b %-d, %y')
    end
  end
end
