require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'quizzes' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  def prepare_quiz
    @quiz = quiz_model({ course: @course, time_limit: 5 })
    @quiz.quiz_questions.create!(question_data: multiple_choice_question_data)
    @quiz.generate_quiz_data
    @quiz.save
    @quiz
  end

  before(:each) do
    course_with_student_logged_in
  end

  context 'with a student' do

    it 'can\'t see unpublished quizzes', priority: "1", test_id: 140651 do
      # create course with an unpublished quiz
      assignment_quiz([], course: @course)
      @quiz.update_attribute(:published_at, nil)
      @quiz.update_attribute(:workflow_state, 'unavailable')

      get "/courses/#{@course.id}/quizzes/"
      expect(f('#content-wrapper')).to include_text 'No quizzes available'
    end

    it 'can see published quizzes', priority: "1", test_id: 220304 do
      # create course with a published quiz
      assignment_quiz([], course: @course)

      get "/courses/#{@course.id}/quizzes/"
      expect(f('#assignment-quizzes')).to be_present
    end

    context 'with a quiz started' do

      before(:each) do
        @qsub = quiz_with_submission(false)
      end

      context 'when attempting to resume a quiz' do
        def update_quiz_lock(lock_at, unlock_at)
          @quiz.update_attributes(lock_at: lock_at, unlock_at: unlock_at)
        end

        describe 'on individual quiz page' do
          def validate_resume_button_text(text)
            expect(f('#not_right_side .take_quiz_button').text).to eq text
          end

          before(:each) do
            @resume_text = 'Resume Quiz'
          end

          it 'can see the resume quiz button if the quiz is unlocked', priority: "1", test_id: 209408 do
            get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
            validate_resume_button_text(@resume_text)
          end

          it 'can see the resume quiz button if the quiz unlock_at date is < now', priority: "1", test_id: 209409 do
            update_quiz_lock(nil, 10.minutes.ago)
            get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
            validate_resume_button_text(@resume_text)
          end

          it 'can\'t see the resume quiz button if quiz is locked', priority: "1", test_id: 209410 do
            update_quiz_lock(5.minutes.ago, nil)
            get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
            expect(f('#not_right_side')).not_to contain_css('.take_quiz_button')
          end

          it 'can\'t see the publish button', priority: "1", test_id: 209411 do
            get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
            expect(f('#content')).not_to contain_css('#quiz-publish-link')
          end

          it 'can\'t see unpublished warning', priority: "1", test_id: 209412 do
            # set to unpublished state
            @quiz.last_edited_at = Time.now.utc
            @quiz.published_at   = 1.hour.ago
            @quiz.save!

            get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

            expect(f('#content')).not_to contain_css('.unpublished_warning')
          end
        end
      end

      context 'when logged out while taking a quiz' do

        it 'is notified and able to relogin', priority: "1", test_id: 209413 do
          # setup a quiz and start taking it
          quiz_with_new_questions(!:goto_edit)
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          expect_new_page_load { f('#take_quiz_link').click }
          sleep 1 # sleep because display is updated on timer, not ajax callback

          # answer a question, and check that it is saved
          ff('.answers .answer_input input')[0].click
          wait_for_ajaximations
          expect(f('#last_saved_indicator').text).to match(/^Quiz saved at \d+:\d+(pm|am)$/)
          # now kill our session (like logging out)
          destroy_session
          sleep 1 # updateSubmission throttles itself at 1 sec (quite
                  # unintelligently, cuz it ignores calls in that second,
                  # so you'd have to wait 15-30 sec for the periodic
                  # update to hit)

          # and try answering another question
          ff('.answers .answer_input input')[1].click

          # we should get notified that we are logged out
          expect(fj('#deauthorized_dialog:visible')).to be_present

          expect_new_page_load { submit_dialog('#deauthorized_dialog') }
        end
      end
    end
  end

  context 'with multiple fill in the blanks' do

    it 'displays MFITB responses in their respective boxes on submission view page', priority: "2", test_id: 209414 do
      # create new multiple fill in the blank quiz and question
      @quiz = quiz_model({ course: @course, time_limit: 5 })

      question = @quiz.quiz_questions.create!(question_data: fill_in_multiple_blanks_question_data)
      @quiz.generate_quiz_data
      @quiz.tap(&:save)
      # create and grade a submission on our mfitb quiz
      qs = @quiz.generate_submission(@student)
      # this generates 6 answers on our submission for each blank in fill_in_multiple_blanks_question_data
      (1..6).each do |var|
        qs.submission_data[
          "question_#{question.id}_#{AssessmentQuestion.variable_id("answer#{var}")}"
        ] = ("this is my answer ##{var}")
      end
      response_array = qs.submission_data.values
      Quizzes::SubmissionGrader.new(qs).grade_submission
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/"
      wait_for_ajaximations
      answer_fields = ff('.question_input')
      answer_array = answer_fields.map { |element| driver.execute_script("return $(arguments[0]).val()", element) }
      expect(answer_array).to eq response_array
    end
  end

  context 'when a student closes the session without submitting' do
    it 'automatically grades the submission when it becomes overdue', priority: "1", test_id: 209415
  end

  context 'when the \'show correct answers\' setting is on' do
    before(:each) do
      prepare_quiz
      @quiz.update_attributes(show_correct_answers: true)
      @quiz.save!
    end

    it 'highlights correct answers', priority: "1", test_id: 209417 do
      take_and_answer_quiz

      expect(ff('.correct_answer').length).to be > 0
    end

    it 'always highlights incorrect answers', priority: "1", test_id: 209418 do
      take_and_answer_quiz do |answers|
        answers[1][:id] # don't answer
      end

      expect(ff('.incorrect.answer_arrow').length).to be > 0
    end
  end

  context "when 'show correct answers after last attempt setting' is on" do
    before(:each) do
      prepare_quiz
      @quiz.update_attributes(:show_correct_answers => true,
        :show_correct_answers_last_attempt => true, :allowed_attempts => 2)
      @quiz.save!
    end

    it "should not show correct answers on first attempt", priority: "1", test_id: 474288 do
      @student = @user
      @observer = user_factory
      @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)

      take_and_answer_quiz
      expect(f("#content")).not_to contain_css('.correct_answer')

      # shouldn't show to an observer either
      user_session(@observer)
      sub = @quiz.quiz_submissions.where(:user_id => @student).first
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{sub.id}"

      expect(f("#content")).not_to contain_css('.correct_answer')

      # attempt two
      user_session(@student)
      take_and_answer_quiz
      expect(ff('.correct_answer').length).to be > 0
    end
  end

  context 'when the \'show correct answers\' setting is off' do

    before(:each) do
      prepare_quiz
      @quiz.update_attributes(show_correct_answers: false)
      @quiz.save!
    end

    it 'doesn\'t highlight correct answers', priority: "1", test_id: 209416 do
      take_and_answer_quiz

      expect(f("#content")).not_to contain_css('.correct_answer')
    end

    it 'always highlights incorrect answers', priority: "1", test_id: 209480 do
      take_and_answer_quiz do |answers|
        answers[1][:id] # don't answer
      end

      expect(ff('.incorrect.answer_arrow').length).to be > 0
    end
  end

  it "should show badge counts after completion", priority: "1", test_id: 474289 do
    prepare_quiz
    take_and_answer_quiz
    expect(f("#section-tabs .grades .nav-badge").text).to eq "1"
  end

  it "should show quiz descriptions to observers" do
    @context = @course
    quiz = quiz_model
    description = "some description"
    quiz.description = description
    quiz.save!

    @student = @user
    @observer = user_factory
    @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
    user_session(@observer)

    open_quiz_show_page
    
    expect(f(".description")).to include_text(description)
  end
end
