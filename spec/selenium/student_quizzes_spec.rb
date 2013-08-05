require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quizzes" do
  it_should_behave_like "quizzes selenium tests"

  context "as a student" do
    before (:each) do
      course_with_student_logged_in
      @qsub = quiz_with_submission(false)
    end

    context "resume functionality" do
      def update_quiz_lock(lock_at, unlock_at)
        @quiz.update_attributes(:lock_at => lock_at, :unlock_at => unlock_at)
        @quiz.reload
        @quiz.save!
      end

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
          update_quiz_lock(Time.now - 1.day.ago, Time.now - 10.minutes.ago)
          get "/courses/#{@course.id}/quizzes"
          f('.description').should include_text('Resume Quiz')
        end

        it "should not show the resume link if the quiz is locked" do
          update_quiz_lock(Time.now - 5.minutes, nil)
          get "/courses/#{@course.id}/quizzes"
          f('.description').should_not include_text('Resume Quiz')
        end

        it "should grade any submission that needs grading" do
          @qsub.end_at = Time.now - 5.minutes
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
          pending('193')
          update_quiz_lock(Time.now - 1.day.ago, Time.now - 10.minutes.ago)
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          validate_resume_button_text(@resume_text)
        end

        it "should not show the resume quiz button if quiz is locked" do
          pending('193')
          update_quiz_lock(Time.now - 5.minutes, nil)
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          f('#not_right_side .take_quiz_button').should_not be_present
        end

        it "should not see the publish button" do
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          f('#quiz-publish-link').should_not be_present
        end
      end
    end

    context "who gets logged out while taking a quiz" do
      it "should be notified and able to relogin" do
        pending('193')
        # setup a quiz and start taking it
        quiz_with_new_questions(!:goto_edit)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect_new_page_load { driver.find_element(:link_text, 'Take the Quiz').click }
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
end
