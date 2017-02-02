require_relative '../common'
require_relative '../helpers/quizzes_common'
require_relative '../helpers/assignment_overrides'

describe 'editing a quiz' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  def delete_quiz
    expect_new_page_load do
      f('.al-trigger').click
      f('.delete_quiz_link').click
      accept_alert
    end
    expect(@quiz.reload).to be_deleted
  end

  context 'as a teacher' do
    before(:once) do
      course_with_teacher(active_all: true)
      create_quiz_with_due_date
    end

    before(:each) do
      user_session(@teacher)
    end

    context 'when the quiz is published' do
      it 'indicates the quiz is published', priority: "1", test_id: 351924 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f('#quiz-draft-state').text.strip).to match accessible_variant_of 'Published'
      end

      it 'hides the |Save and Publish| button', priority: "1", test_id: 255478 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f("#content")).not_to contain_css('.save_and_publish')
      end

      it 'shows the speedgrader link', priority: "1", test_id: 351926 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f('.icon-speed-grader')).to be_displayed
      end

      it 'remains published after saving changes', priority: "1", test_id: 210059 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        type_in_tiny('#quiz_description', 'changed description')
        click_save_settings_button
        expect(f('#quiz-publish-link')).to include_text 'Published'
      end

      it 'deletes the quiz', priority: "1", test_id: 351921 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        delete_quiz
      end

      it 'saves question changes with the |Save it now| button', priority: "1", test_id: 140647 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        # add new question without saving changes
        click_questions_tab
        click_new_question_button
        create_file_upload_question
        cancel_quiz_edit

        # verify alert
        alert_box = f('.alert .unpublished_warning')
        expect(alert_box.text).to \
          eq "You have made changes to the questions in this quiz.\nThese "\
            "changes will not appear for students until you save the quiz."

        # verify button
        save_it_now_button = fj('.btn.btn-primary', '.edit_quizzes_quiz')
        expect(save_it_now_button).to be_displayed

        # verify the alert disappears after clicking the button
        save_it_now_button.click
        expect(f('.alert .unpublished_warning')).not_to be_displayed

        expect { @quiz.quiz_questions.count }.to become(1)
      end
    end

    context 'when the quiz isn\'t published' do
      before(:once) do
        @quiz.workflow_state = 'unavailable'
        @quiz.save!
      end

      it 'indicates the quiz is unpublished', priority: "1", test_id: 351925 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f('#quiz-draft-state').text.strip).to match accessible_variant_of 'Not Published'
      end

      it 'hides the speedgrader link', priority: "1", test_id: 351927 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f("#content")).not_to contain_css('.icon-speed-grader')
      end

      it 'shows the |Save and Publish| button', priority: "1", test_id: 255479 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f('.save_and_publish')).to be_displayed
      end

      it 'deletes the quiz', priority: "1", test_id: 351922 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        delete_quiz
      end

      it 'publishes the quiz', priority: "1", test_id: 351928 do
        skip_if_chrome('research')
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        f('#quiz-publish-link.btn-publish').click
        expect(f('#quiz-publish-link')).to include_text 'Unpublish'
      end
    end

    it 'hides question form when cancelling edit', priority: "1", test_id: 209956 do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      wait_for_tiny f('#quiz_description')
      click_questions_tab
      click_new_question_button
      f('.question_holder .question_form .cancel_link').click
      expect(f('.question_holder')).not_to contain_css('.question_form')
    end

    it 'changes the quiz\'s description', priority: "1", test_id: 210057 do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

      test_text = 'changed description'
      type_in_tiny '#quiz_description', test_text, clear: true

      click_save_settings_button
      expect { @quiz.reload.description }.to become("<p>#{test_text}</p>")
    end

    it 'loads existing due date', priority: "1", test_id: 209961 do
      wait_for_ajaximations
      compare_assignment_times(@quiz.reload)
    end

    context 'when the quiz has a submission' do
      before(:once) do
        quiz_with_submission
      end

      before(:each) do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      end

      it 'flashes a warning message', priority: "1", test_id: 140609 do
        message = 'Keep in mind, some students have already taken or started taking this quiz'
        expect(f('#flash_message_holder')).to include_text message
      end

      it 'deletes the quiz', priority: "1", test_id: 210073 do
        delete_quiz
      end
    end

    context 'when the quiz has a question with a custom name' do
      before(:each) do
        @custom_name = 'the hardest question ever'
        qd = { question_type: "text_only_question", id: 1, question_name: @custom_name}.with_indifferent_access
        @quiz.quiz_questions.create! question_data: qd
        @quiz.save!
        @quiz.reload
      end

      it 'displays the custom name correctly' do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        click_questions_tab
        expect(f('.question_name')).to include_text @custom_name
      end
    end
  end
end
