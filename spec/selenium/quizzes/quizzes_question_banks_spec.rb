require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/testrail_report')

describe 'quizzes question banks' do

  include_context 'in-process server selenium tests'

  context 'when logged in as a teacher' do

    before(:each) do
      course_with_teacher_logged_in
    end

    it 'should be able to create question bank', priority: "1", test_id: 140667 do
      # report_test(72402) do
      get "/courses/#{@course.id}/question_banks"
      question_bank_title = keep_trying_until do
        f('.add_bank_link').click
        wait_for_ajaximations
        question_bank_title = f('#assessment_question_bank_title')
        expect(question_bank_title).to be_displayed
        question_bank_title
      end
      question_bank_title.send_keys('goober', :return)
      wait_for_ajaximations
      question_bank = AssessmentQuestionBank.where(title: 'goober').first
      expect(question_bank).to be_present
      expect(question_bank.workflow_state).to eq 'active'
      expect(f('#question_bank_adding .title')).to(include_text('goober'))
      expect(question_bank.bookmarked_for?(User.last)).to be_truthy
      question_bank
    end

    it 'should be able to create quiz questions', priority: "1", test_id: 140668 do
      # report_test(72403) do
      bank = AssessmentQuestionBank.create!(context: @course)
      get "/courses/#{@course.id}/question_banks/#{bank.id}"

      f('.add_question_link').click
      wait_for_ajaximations
      expect { create_multiple_choice_question }.to change(AssessmentQuestion, :count).by(1)
    end

    it 'should tally up question bank question points', priority: "1", test_id: 201930 do
      quiz = @course.quizzes.create!(title: 'My Quiz')
      bank = AssessmentQuestionBank.create!(context: @course)
      3.times { assessment_question_model(bank: bank) }
      harder = bank.assessment_questions.last
      harder.question_data[:points_possible] = 15
      harder.save!
      get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
      find_questions_link = f('.find_question_link')
      click_questions_tab
      keep_trying_until {
        find_questions_link.click
        wait_for_ajaximations
        f('.select_all_link')
      }.click
      submit_dialog('#find_question_dialog', '.submit_button')
      wait_for_ajaximations
      click_settings_tab
      keep_trying_until { expect(fj('#quiz_display_points_possible .points_possible').text).to eq '17' }
    end

    it 'should allow you to use inherited question banks', priority: "1", test_id: 201931 do
      @course.account = Account.default
      @course.save
      quiz = @course.quizzes.create!(title: 'My Quiz')
      bank = AssessmentQuestionBank.create!(context: @course.account)
      assessment_question_model(bank: bank)

      get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
      click_questions_tab

      keep_trying_until do
        f('.find_question_link').click
        wait_for_ajaximations
        expect(f('#find_question_dialog')).to be_displayed
        expect(f('.select_all_link')).to be_displayed
      end
      f('.select_all_link').click
      wait_for_ajaximations
      submit_dialog('#find_question_dialog', '.submit_button')
      wait_for_ajaximations
      click_settings_tab
      keep_trying_until { expect(fj('#quiz_display_points_possible .points_possible').text).to eq '1' }

      click_questions_tab
      f('.add_question_group_link').click
      wait_for_ajaximations
      f('.find_bank_link').click
      keep_trying_until { fj('#find_bank_dialog .bank:visible') }.click
      submit_dialog('#find_bank_dialog', '.submit_button')
      submit_form('.quiz_group_form')
      wait_for_ajaximations
      click_settings_tab
      keep_trying_until { expect(fj('#quiz_display_points_possible .points_possible').text).to eq '2' }
    end

    it 'should allow you to use bookmarked question banks', priority: "1", test_id: 201932 do
      @course.account = Account.default
      @course.save
      quiz = @course.quizzes.create!(title: 'My Quiz')
      bank = AssessmentQuestionBank.create!(context: Course.create!)
      assessment_question_model(bank: bank)
      @user.assessment_question_banks << bank

      get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
      click_questions_tab

      keep_trying_until do
        f('.find_question_link').click
        wait_for_ajaximations
        expect(f('#find_question_dialog')).to be_displayed
        wait_for_ajaximations
        expect(f('.select_all_link')).to be_displayed
      end
      f('.select_all_link').click
      wait_for_ajaximations
      submit_dialog('#find_question_dialog', '.submit_button')
      wait_for_ajaximations
      click_settings_tab
      keep_trying_until { expect(fj('#quiz_display_points_possible .points_possible').text).to eq '1' }

      click_questions_tab
      f('.add_question_group_link').click
      wait_for_ajaximations
      f('.find_bank_link').click
      wait_for_ajaximations
      keep_trying_until { fj('#find_bank_dialog .bank:visible') }.click
      submit_dialog('#find_bank_dialog', '.submit_button')
      submit_form('.quiz_group_form')
      wait_for_ajaximations
      click_settings_tab
      keep_trying_until { expect(fj('#quiz_display_points_possible .points_possible').text).to eq '2' }
    end

    it 'should check permissions when retrieving question banks', priority: "1", test_id: 201933 do
      @course.account = Account.default
      @course.account.role_overrides.create(
        permission: 'read_question_banks',
        role: teacher_role,
        enabled: false
      )
      @course.save
      quiz = @course.quizzes.create!(title: 'My Quiz')

      course_bank = AssessmentQuestionBank.create!(context: @course)
      assessment_question_model(bank: course_bank)

      account_bank = AssessmentQuestionBank.create!(context: @course.account)
      assessment_question_model(bank: account_bank)

      get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
      click_questions_tab

      keep_trying_until do
        f('.find_question_link').click
        wait_for_ajaximations
        expect(f('#find_question_dialog')).to be_displayed
        expect(f('.select_all_link')).to be_displayed
      end
      expect(ffj('#find_question_dialog .bank:visible').size).to eq 1

      close_visible_dialog
      keep_trying_until do
        f('.add_question_group_link').click
        wait_for_ajaximations
        expect(f('.find_bank_link')).to be_displayed
      end
      f('.find_bank_link').click
      wait_for_ajaximations
      expect(ffj('#find_bank_dialog .bank:visible').size).to eq 1
    end

    it 'should create a question group from a question bank', priority: "1", test_id: 319907 do
      get "/courses/#{@course.id}/quizzes/new"
      click_questions_tab

      f('.add_question_group_link').click
      wait_for_ajaximations
      group_form = f('#group_top_new .quiz_group_form')
      group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
      replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '2')
      submit_form(group_form)
      expect(f('#questions .group_top .group_display.name')).to include_text('new group')
    end

    it 'deleting AJAX-loaded questions should work', priority: "2", test_id: 201938 do
      @bank = @course.assessment_question_banks.create!(title: 'Test Bank')
      (1..60).each do |idx|
        @bank.assessment_questions.create!(
          question_data: {
            question_name: "test question #{idx}",
            answers: [
              { id: 1 },
              { id: 2 }
            ]
          }
        )
      end
      get "/courses/#{@course.id}/question_banks/#{@bank.id}"
      f('.more_questions_link').click
      wait_for_ajaximations
      keep_trying_until do
        expect(ffj('.display_question:visible').length).to eq 60
        driver.execute_script("$('.display_question .links a').css('left', '0')")
        wait_for_ajaximations
        driver.execute_script('window.confirm = function(msg) { return true; };')
        wait_for_ajaximations
        fj('.display_question:visible:last .delete_question_link').click
        wait_for_ajaximations
        expect(ffj('.display_question:visible').length).to eq 59
      end
      @bank.reload
      wait_for_ajaximations
      expect(@bank.assessment_questions.select { |aq| !aq.deleted? }.length).to eq 59
    end

    it 'should allow editing quiz questions that belong to a quiz bank', priority: "1", test_id: 217531 do
      @course.account = Account.default
      @course.save

      # create quiz that pulls from question bank
      quiz_with_new_questions true

      # create question group, fill with existing question bank questions
      create_question_group
      drag_question_into_group(@quest1.id, @group.id)
      drag_question_into_group(@quest2.id, @group.id)
      click_save_settings_button

      # modify a quiz bank question
      new_name = 'I have been edited'
      new_question_text = "What is the answer to #{new_name}?"

      get "/courses/#{@course.id}/quizzes/#{@q.id}/edit"
      click_questions_tab
      hover_and_click("#question_#{@quest1.id} .edit_question_link")
      replace_content(f('.question_form [name=\'question_name\']'), new_name)
      type_in_tiny('.question_content', new_question_text)
      submit_form('.question_form')
      click_save_settings_button

      # verify modifications
      get "/courses/#{@course.id}/quizzes/#{@q.id}/edit"
      click_questions_tab

      expect(f("#question_#{@quest1.id}")).to include_text new_name
      expect(f("#question_#{@quest1.id}")).to include_text new_question_text
    end
  end
end
