require_relative '../common'
require_relative '../helpers/quizzes_common'
require_relative '../helpers/assignment_overrides'
require_relative '../helpers/files_common'

describe 'creating a quiz' do
  include_context 'in-process server selenium tests'
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper
  include FilesCommon

  context 'as a teacher' do
    before(:each) do
      course_with_teacher_logged_in(course_name: 'Test Course', active_all: true)
    end

    context 'when the course has two sections' do
      before(:each) do
        @section_a = @course.course_sections.first
        @section_b = @course.course_sections.create!(name: 'Section B')
        course_quiz(active: true)
        open_quiz_edit_form
      end

      it 'sets availability dates and due dates for each section', priority: 1, test_id: 140670 do
        assign_quiz_to_no_one

        # assign to default section
        now = Time.zone.now
        due_at_a = default_time_for_due_date(now.advance(days: 3))
        unlock_at_a = default_time_for_unlock_date(now.advance(days: -3))
        lock_at_a = default_time_for_lock_date(now.advance(days: 3))

        assign_dates_for_first_override_section(
          due_at: due_at_a,
          unlock_at: unlock_at_a,
          lock_at: lock_at_a
        )

        # assign to Section B
        due_at_b = default_time_for_due_date(now.advance(days: 5))
        unlock_at_b = default_time_for_unlock_date(now.advance(days: -1))
        lock_at_b = default_time_for_lock_date(now.advance(days: 5))

        add_override
        assign_dates_for_last_override_section(
          due_at: due_at_b,
          unlock_at: unlock_at_b,
          lock_at: lock_at_b
        )

        # Must select sections after setting dates in order to avoid intermittent failure.
        # Workaround is to set the dates using the date-selector tools.
        select_first_override_section(@section_a.name)
        select_last_override_section(@section_b.name)
        save_settings

        # verify default section due date & availability dates
        expect(obtain_due_date(@section_a)).to include_text("#{format_time_for_view(due_at_a)}")
        expect(obtain_availability_start_date(@section_a)).to include_text("#{format_time_for_view(unlock_at_a)}")
        expect(obtain_availability_end_date(@section_a)).to include_text("#{format_time_for_view(lock_at_a)}")

        # verify Section B due date & availability dates
        expect(obtain_due_date(@section_b)).to include_text("#{format_time_for_view(due_at_b)}")
        expect(obtain_availability_start_date(@section_b)).to include_text("#{format_time_for_view(unlock_at_b)}")
        expect(obtain_availability_end_date(@section_b)).to include_text("#{format_time_for_view(lock_at_b)}")
      end
    end

    it 'prevents assigning a quiz to no one', priority: 1, test_id: 385155 do
      course_quiz(active: true)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      assign_quiz_to_no_one
      save_settings

      expect(ffj('div.error_text', 'div.error_box.errorBox')[1].text).to eq 'You ' \
        'must have a student or section selected'
    end

    it 'saves and publishes a new quiz', priority: "1", test_id: 193785 do
      @quiz = course_quiz
      open_quiz_edit_form

      expect(f('#quiz-draft-state')).to be_displayed

      expect_new_page_load {f('.save_and_publish').click}
      expect(f('#quiz-publish-link.btn-published')).to be_displayed

      # Check that the list of quizzes is also updated
      get "/courses/#{@course.id}/quizzes"
      expect(f("#summary_quiz_#{@quiz.id} .icon-publish")).to be_displayed
    end

    context 'when on the quizzes index page' do
      before(:each) do
        get "/courses/#{@course.id}/quizzes"
        expect_new_page_load do
          f('.new-quiz-link').click
        end
      end

      it 'creates a quiz directly from the index page', priority: "1", test_id: 210055 do
        expect_new_page_load do
          click_save_settings_button
        end
        expect(f('#quiz_title')).to include_text 'Unnamed Quiz'
      end

      it 'redirects to the correct quiz edit form', priority: "2", test_id: 399887 do
        # check url
        expect(driver.current_url).to match %r{/courses/\d+/quizzes/\d+\/edit}

        # check quiz id
        # The =~ operator compares the regex with the string.
        # The (?<quiz_id>(\d+)) part of the regex tells the =~ to assign
        # the value of the number found therein to the variable, quiz_id.
        %r courses/\d+/quizzes/(?<quiz_id>(\d+))/edit =~ driver.current_url
        expect(quiz_id.to_i).to be > 0
      end

      it 'creates and previews a new quiz', priority: "1", test_id: 210056 do
        # input name and description then save quiz
        replace_content(f('#quiz_title'), 'new quiz')
        description_text = 'new description'
        expect(f('#quiz_description_ifr')).to be_displayed
        type_in_tiny '#quiz_description', description_text
        in_frame 'quiz_description_ifr' do
          expect(f('#tinymce')).to include_text(description_text)
        end

        # add a question
        click_questions_tab
        click_new_question_button
        submit_form('.question_form')
        wait_for_ajaximations

        # save the quiz
        expect_new_page_load do
          click_save_settings_button
          wait_for_ajaximations
        end
        wait_for_ajaximations

        # check quiz preview
        f('#preview_quiz_button').click
        expect(f('#questions')).to be_present
      end
    end

    it 'inserts files using the rich content editor', priority: "1", test_id: 132545 do
      txt_files = ['some test file', 'b_file.txt']
      txt_files.map do |text_file|
        file = @course.attachments.create!(display_name: text_file, uploaded_data: default_uploaded_data)
        file.context = @course
        file.save!
      end
      @quiz = course_quiz
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      insert_file_from_rce(:quiz)
      expect(fln('b_file.txt')).to be_displayed
    end
  end

  context "post to sis default setting" do
    before do
      account_model
      @account.set_feature_flag! 'post_grades', 'on'
      course_with_teacher_logged_in(:active_all => true, :account => @account)
    end

    it "should default to post grades if account setting is enabled" do
      @account.settings[:sis_default_grade_export] = {:locked => false, :value => true}
      @account.save!

      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load do
        f('.new-quiz-link').click
        wait_for_ajaximations
      end
      expect(is_checked('#assignment_post_to_sis')).to be_truthy
    end

    it "should not default to post grades if account setting is not enabled" do
      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load do
        f('.new-quiz-link').click
        wait_for_ajaximations
      end
      expect(is_checked('#assignment_post_to_sis')).to be_falsey
    end
  end
end
