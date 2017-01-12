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
    before(:each) do
      course_with_teacher_logged_in
      create_quiz_with_due_date
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
    end

    context 'when the quiz is published' do
      it 'indicates the quiz is published', priority: "1", test_id: 351924 do
        expect(f('#quiz-draft-state').text.strip).to match accessible_variant_of 'Published'
      end

      it 'hides the |Save and Publish| button', priority: "1", test_id: 255478 do
        expect(f("#content")).not_to contain_css('.save_and_publish')
      end

      it 'shows the speedgrader link', priority: "1", test_id: 351926 do
        expect_new_page_load do
          click_save_settings_button
        end
        expect(f('.icon-speed-grader')).to be_displayed
      end

      it 'remains published after saving changes', priority: "1", test_id: 210059 do
        type_in_tiny('#quiz_description', 'changed description')
        click_save_settings_button
        expect(f('#quiz-publish-link')).to include_text 'Published'
      end

      it 'deletes the quiz', priority: "1", test_id: 351921 do
        delete_quiz
      end

      it 'saves question changes with the |Save it now| button', priority: "1", test_id: 140647 do
        course_with_student(course: @course, active_enrollment: true)

        # add new question without saving changes
        click_questions_tab
        click_new_question_button
        question_description = 'New Test Question'
        create_multiple_choice_question(description: question_description)
        cancel_quiz_edit

        # verify alert
        alert_box = fj('.unpublished_warning', '.alert')
        expect(alert_box.text).to \
          eq "You have made changes to the questions in this quiz.\nThese "\
            "changes will not appear for students until you save the quiz."

        # verify button
        save_it_now_button = fj('.btn.btn-primary', '.edit_quizzes_quiz')
        expect(save_it_now_button).to be_displayed

        # verify the alert disappears after clicking the button
        save_it_now_button.click
        wait_for_ajaximations
        expect(fj('.unpublished_warning', '.alert')).not_to be_displayed

        # verify the student sees the changes
        user_session(@student)
        take_quiz do
          expect(f('.display_question.question.multiple_choice_question')).to \
            include_text question_description
        end
      end
    end

    context 'when the quiz isn\'t published' do
      before(:each) do
        @quiz.workflow_state = 'unavailable'
        @quiz.save!
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      end

      it 'indicates the quiz is unpublished', priority: "1", test_id: 351925 do
        expect(f('#quiz-draft-state').text.strip).to match accessible_variant_of 'Not Published'
      end

      it 'hides the speedgrader link', priority: "1", test_id: 351927 do
        expect_new_page_load do
          click_save_settings_button
        end
        expect(f("#content")).not_to contain_css('.icon-speed-grader')
      end

      it 'shows the |Save and Publish| button', priority: "1", test_id: 255479 do
        expect(f('.save_and_publish')).to be_displayed
      end

      it 'deletes the quiz', priority: "1", test_id: 351922 do
        delete_quiz
      end

      it 'publishes the quiz', priority: "1", test_id: 351928 do
        skip_if_chrome('research')
        expect_new_page_load do
          click_save_settings_button
        end
        f('#quiz-publish-link.btn-publish').click
        expect(f('#quiz-publish-link')).to include_text 'Unpublish'
      end
    end

    it 'hides question form when cancelling edit', priority: "1", test_id: 209956 do
      wait_for_tiny f('#quiz_description')
      click_questions_tab
      click_new_question_button
      f('.question_holder .question_form .cancel_link').click
      expect(f('.question_holder')).not_to contain_css('.question_form')
    end

    it 'changes the quiz\'s description', priority: "1", test_id: 210057 do
      wait_for_ajaximations
      expect(f('#quiz_description_ifr')).to be_displayed

      test_text = 'changed description'
      type_in_tiny '#quiz_description', test_text
      in_frame 'quiz_description_ifr' do
        expect(f('#tinymce')).to include_text(test_text)
      end

      click_save_settings_button
      wait_for_ajaximations

      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      expect(f('#main .description')).to include_text(test_text)
    end

    it 'loads existing due date', priority: "1", test_id: 209961 do
      wait_for_ajaximations
      compare_assignment_times(@quiz.reload)
    end

    it 'overrides quiz details', priority: "2", test_id: 210074 do
      skip('This spec is frail')
      default_section = @course.course_sections.first
      other_section = @course.course_sections.create!(name: 'other section')
      default_section_due = Time.zone.now + 1.day
      other_section_due = Time.zone.now + 2.days
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      wait_for_ajaximations
      select_first_override_section(default_section.name)
      first_due_at_element.clear
      first_due_at_element.
          send_keys(format_date_for_view(default_section_due))

      add_override

      select_last_override_section(other_section.name)
      last_due_at_element.
          send_keys(format_date_for_view(other_section_due))
      expect_new_page_load do
        click_save_settings_button
        wait_for_ajax_requests
      end
      overrides = @quiz.reload.assignment_overrides
      expect(overrides.size).to eq 2
      default_override = overrides.detect { |o| o.set_id == default_section.id }
      expect(default_override.due_at.to_date).
          to eq default_section_due.to_date
      other_override = overrides.detect { |o| o.set_id == other_section.id }
      expect(other_override.due_at.to_date).
          to eq other_section_due.to_date
    end

    context 'when the quiz has a submission' do
      before(:each) do
        quiz_with_submission
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
