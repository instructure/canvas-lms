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
          f('#right-side .btn').text.should == text
        end
        
        before do
          @resume_text = 'Resume Quiz'
        end

        it "should show the resume quiz button if the quiz is unlocked" do
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          validate_resume_button_text(@resume_text)
        end

        it "should show the resume quiz button if the quiz unlock_at date is < now" do
          update_quiz_lock(Time.now - 1.day.ago, Time.now - 10.minutes.ago)
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          validate_resume_button_text(@resume_text)
        end

        it "should not show the resume quiz button if quiz is locked" do
          update_quiz_lock(Time.now - 5.minutes, nil)
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          right_side = f('#right-side')
          right_side.should_not include_text("You're in the middle of taking this quiz.")
          right_side.should_not include_text(@resume_text)
        end
      end
    end
  end
end

