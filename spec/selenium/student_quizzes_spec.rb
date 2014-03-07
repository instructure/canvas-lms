require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes" do
  include_examples "quizzes selenium tests"

  def prepare_quiz
    @quiz = quiz_model({
      :course => @course,
      :time_limit => 5
    })

    @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)
    @quiz.generate_quiz_data
    @quiz.save
    @quiz
  end

  context "as a student" do
    before (:each) do
      course_with_student_logged_in
      @qsub = quiz_with_submission(false)
    end

    context "resume functionality" do
      def update_quiz_lock(lock_at, unlock_at)
        @quiz.update_attributes(:lock_at => lock_at, :unlock_at => unlock_at)
      end

      # This feature doesn't exist for draft state yet
      describe "on main page" do
        def validate_description_text(does_contain_text, text)
          description = f('.description')
          if does_contain_text
            description.should include_text(text)
          else
            description.should_not include_text(text)
          end
        end

        it "should show the resume quiz link if quiz is unlocked" do
          get "/courses/#{@course.id}/quizzes"
          f('.description').should include_text('Resume Quiz')
        end

        it "should show the resume quiz link if quiz unlock_at date is < now" do
          update_quiz_lock(nil, 10.minutes.ago)
          get "/courses/#{@course.id}/quizzes"
          f('.description').should include_text('Resume Quiz')
        end

        it "should not show the resume link if the quiz is locked" do
          update_quiz_lock(5.minutes.ago, nil)
          get "/courses/#{@course.id}/quizzes"
          f('.description').should_not include_text('Resume Quiz')
        end

        it "should grade any submission that needs grading" do
          @qsub.end_at = 5.minutes.ago
          @qsub.save!
          get "/courses/#{@course.id}/quizzes"
          f('.description').should_not include_text('Resume Quiz')
          f('.description').should include_text('0 out of')
        end
      end

      describe "on individual quiz page" do
        def validate_resume_button_text(text)
          f('#not_right_side .take_quiz_button').text.should == text
        end

        before do
          @resume_text = 'Resume Quiz'
        end

        it "should show the resume quiz button if the quiz is unlocked" do
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          validate_resume_button_text(@resume_text)
        end

        it "should show the resume quiz button if the quiz unlock_at date is < now" do
          update_quiz_lock(nil, 10.minutes.ago)
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          validate_resume_button_text(@resume_text)
        end

        it "should not show the resume quiz button if quiz is locked" do
          update_quiz_lock(5.minutes.ago, nil)
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          f('#not_right_side .take_quiz_button').should_not be_present
        end

        it "should not see the publish button" do
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          f('#quiz-publish-link').should_not be_present
        end

        it "should not see unpublished warning" do
          # set to unpublished state
          @quiz.last_edited_at = Time.now.utc
          @quiz.published_at   = 1.hour.ago
          @quiz.save!

          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

          f(".unpublished_warning").should_not be_present
        end
      end
    end

    context "who gets logged out while taking a quiz" do
      it "should be notified and able to relogin" do
        pending('193')
        # setup a quiz and start taking it
        quiz_with_new_questions(!:goto_edit)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect_new_page_load { f("#take_quiz_link").click }
        sleep 1 # sleep because display is updated on timer, not ajax callback

        # answer a question, and check that it is saved
        ff('.answers .answer_input input')[0].click
        wait_for_ajaximations
        f('#last_saved_indicator').text.should match(/^Quiz saved at \d+:\d+(pm|am)$/)

        # now kill our session (like logging out)
        destroy_session(@pseudonym, false)

        index = 1
        keep_trying_until {
          # and try answering another question
          ff('.answers .answer_input input')[index].click
          wait_for_ajaximations

          # we should get notified that we are logged out
          fj('#deauthorized_dialog:visible').should be_present
          index = (index + 1) % 2
        }

        expect_new_page_load { submit_dialog('#deauthorized_dialog') }

        # log back in
        expect_new_page_load { fill_in_login_form(@pseudonym.unique_id, @pseudonym.password) }

        # we should be back at the quiz show page
        driver.find_element(:link_text, 'Resume Quiz').should be_present
      end
    end
  end

  context "who closes the session without submitting" do
    it "should automatically grade the submission when it becomes overdue" do
      job_tag = 'Quizzes::QuizSubmission#grade_if_untaken'

      course_with_student_logged_in
      quiz = prepare_quiz

      Delayed::Job.find_by_tag(job_tag).should == nil

      take_and_answer_quiz(false)

      driver.execute_script("window.close()")

      quiz_sub = @quiz.quiz_submissions.find_by_user_id(@user.id)
      quiz_sub.should be_present
      quiz_sub.workflow_state.should == "untaken"

      job = Delayed::Job.find_by_tag(job_tag)
      job.should be_present

      # okay, we will manually "run" the job because we can't afford to wait
      # for it to be picked up by DJ in a spec:
      auto_grader = YAML.parse(job.handler).transform
      auto_grader.perform

      quiz_sub.reload
      quiz_sub.workflow_state.should == "complete"
    end
  end

  context "correct answer visibility" do
    before(:each) do
      course_with_student_logged_in
      prepare_quiz
    end

    it "should not highlight correct answers" do
      @quiz.update_attributes(show_correct_answers: false)
      @quiz.save!

      take_and_answer_quiz

      ff('.correct_answer').length.should == 0
    end

    it "should highlight correct answers" do
      @quiz.update_attributes(show_correct_answers: true)
      @quiz.save!

      take_and_answer_quiz

      ff('.correct_answer').length.should > 0
    end

    it "should always highlight incorrect answers" do
      @quiz.update_attributes(show_correct_answers: false)
      @quiz.save!

      take_and_answer_quiz do |answers|
        answers[1][:id] # don't answer
      end

      ff('.incorrect.answer_arrow').length.should > 0
    end
  end
end
