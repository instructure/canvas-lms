require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe 'quizzes' do
  include_context 'in-process server selenium tests'

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

      context 'when taking a timed quiz' do

        it 'warns the student before the lock date is exceeded', priority: "1", test_id: 209407 do
          @context = @course
          bank = @course.assessment_question_banks.create!(title: 'Test Bank')
          q = quiz_model
          a = bank.assessment_questions.create!
          answers = [
            {
              id: 1,
              answer_text: 'A',
              weight: 100
            },
            {
              id: 2,
              answer_text: 'B',
              weight: 0
            }
          ]
          question = q.quiz_questions.create!(
            question_data: {
              name: 'first question',
              question_type: 'multiple_choice_question',
              answers: answers,
              points_possible: 1
            }, assessment_question: a
          )

          q.generate_quiz_data
          q.lock_at = Time.now.utc + 5.seconds
          q.save!

          get "/courses/#{@course.id}/quizzes/#{q.id}/take?user_id=#{@student.id}"
          f('#take_quiz_link').click
          answer_one = f("#question_#{question.id}_answer_1")

          # force a save to create a submission
          answer_one.click
          wait_for_ajaximations

          keep_trying_until do
            Quizzes::QuizSubmission.last
            expect(fj('#times_up_dialog:visible')).to be_present
          end
        end
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
            expect(f('#not_right_side .take_quiz_button')).not_to be_present
          end

          it 'can\'t see the publish button', priority: "1", test_id: 209411 do
            get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
            expect(f('#quiz-publish-link')).not_to be_present
          end

          it 'can\'t see unpublished warning', priority: "1", test_id: 209412 do
            # set to unpublished state
            @quiz.last_edited_at = Time.now.utc
            @quiz.published_at   = 1.hour.ago
            @quiz.save!

            get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

            expect(f('.unpublished_warning')).not_to be_present
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
          destroy_session(false)

          index = 1
          keep_trying_until do
            # and try answering another question
            ff('.answers .answer_input input')[index].click
            wait_for_ajaximations

            # we should get notified that we are logged out
            expect(fj('#deauthorized_dialog:visible')).to be_present
            index = (index + 1) % 2
          end

          expect_new_page_load { submit_dialog('#deauthorized_dialog') }

          # log back in
          expect_new_page_load { fill_in_login_form(@pseudonym.unique_id, @pseudonym.password) }

          # we should be back at the quiz show page
          expect(fln('Resume Quiz')).to be_present
        end
      end
    end
  end

  context 'with multiple fill in the blanks' do

    it 'displays MFITB responses in their respective boxes on submission view page', priority: "2", test_id: 209414 do
      # create new multiple fill in the blank quiz and question
      @quiz = quiz_model({ course: @course, time_limit: 5 })

      question = @quiz.quiz_questions.create!(question_data: fill_in_multiple_blanks_question_data )
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

    it 'automatically grades the submission when it becomes overdue', priority: "1", test_id: 209415 do
      skip('disabled because of regression')

      job_tag = 'Quizzes::QuizSubmission#grade_if_untaken'

      prepare_quiz

      expect(Delayed::Job.find_by_tag(job_tag)).to eq nil

      take_and_answer_quiz(false)

      driver.execute_script('window.close()')

      quiz_sub = @quiz.quiz_submissions.where(user_id: @user).first
      expect(quiz_sub).to be_present
      expect(quiz_sub.workflow_state).to eq 'untaken'

      job = Delayed::Job.find_by_tag(job_tag)
      expect(job).to be_present

      # okay, we will manually "run" the job because we can't afford to wait
      # for it to be picked up by DJ in a spec:
      auto_grader = YAML.parse(job.handler).transform
      auto_grader.perform

      quiz_sub.reload
      expect(quiz_sub.workflow_state).to eq 'complete'
    end
  end

  context 'when the \'show correct answers\' setting is on' do

    before(:each) do
      prepare_quiz
    end

    it 'highlights correct answers', priority: "1", test_id: 209417 do
      @quiz.update_attributes(show_correct_answers: true)
      @quiz.save!

      take_and_answer_quiz

      expect(ff('.correct_answer').length).to be > 0
    end

    it 'always highlights incorrect answers', priority: "1", test_id: 209418 do
      @quiz.update_attributes(show_correct_answers: true)
      @quiz.save!

      take_and_answer_quiz do |answers|
        answers[1][:id] # don't answer
      end

      expect(ff('.incorrect.answer_arrow').length).to be > 0
    end
  end

  context 'when the \'show correct answers\' setting is off' do

    before(:each) do
      prepare_quiz
    end

    it 'doesn\'t highlight correct answers', priority: "1", test_id: 209416 do
      @quiz.update_attributes(show_correct_answers: false)
      @quiz.save!

      take_and_answer_quiz

      expect(ff('.correct_answer').length).to eq 0
    end

    it 'always highlights incorrect answers', priority: "1", test_id: 209480 do
      @quiz.update_attributes(show_correct_answers: false)
      @quiz.save!

      take_and_answer_quiz do |answers|
        answers[1][:id] # don't answer
      end

      expect(ff('.incorrect.answer_arrow').length).to be > 0
    end
  end
end
