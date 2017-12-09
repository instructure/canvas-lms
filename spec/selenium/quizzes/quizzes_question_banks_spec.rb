#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'quizzes question banks' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context 'as a teacher' do

    before(:each) do
      course_with_teacher_logged_in
    end

    it 'should be able to create question bank', priority: "1", test_id: 140667 do
      get "/courses/#{@course.id}/question_banks"
      f('.add_bank_link').click
      wait_for_ajaximations
      question_bank_title = f('#assessment_question_bank_title')
      expect(question_bank_title).to be_displayed
      question_bank_title.send_keys('goober', :return)
      wait_for_ajaximations
      question_bank = AssessmentQuestionBank.where(title: 'goober').first
      expect(question_bank).to be_present
      expect(question_bank.workflow_state).to eq 'active'
      expect(f('#question_bank_adding .title')).to(include_text('goober'))
      expect(driver.switch_to.active_element).to eq(f('#question_bank_adding .title'))
      expect(question_bank.bookmarked_for?(User.last)).to be_truthy
      question_bank
    end

    it 'adds a basic multiple choice question to a question bank', priority: "1", test_id: 140668 do
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
      find_questions_link.click
      wait_for_ajaximations
      f('.select_all_link').click
      submit_dialog('#find_question_dialog', '.submit_button')
      wait_for_ajaximations
      click_settings_tab
      expect(f('#quiz_display_points_possible .points_possible')).to include_text '17'
    end

    it 'should allow you to use inherited question banks', priority: "1", test_id: 201931 do
      @course.account = Account.default
      @course.save
      quiz = @course.quizzes.create!(title: 'My Quiz')
      bank = AssessmentQuestionBank.create!(context: @course.account)
      assessment_question_model(bank: bank)

      get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
      click_questions_tab

      f('.find_question_link').click
      wait_for_ajaximations
      expect(f('#find_question_dialog')).to be_displayed
      expect(f('.select_all_link')).to be_displayed
      f('.select_all_link').click
      wait_for_ajaximations
      submit_dialog('#find_question_dialog', '.submit_button')
      wait_for_ajaximations
      click_settings_tab
      expect(f('#quiz_display_points_possible .points_possible')).to include_text '1'

      click_questions_tab
      f('.add_question_group_link').click
      wait_for_ajaximations
      f('.find_bank_link').click
      fj('#find_bank_dialog .bank:visible').click
      submit_dialog('#find_bank_dialog', '.submit_button')
      submit_form('.quiz_group_form')
      wait_for_ajaximations
      click_settings_tab
      expect(f('#quiz_display_points_possible .points_possible')).to include_text '2'
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

      f('.find_question_link').click
      wait_for_ajaximations
      expect(f('#find_question_dialog')).to be_displayed
      wait_for_ajaximations
      expect(f('.select_all_link')).to be_displayed
      f('.select_all_link').click
      wait_for_ajaximations
      submit_dialog('#find_question_dialog', '.submit_button')
      wait_for_ajaximations
      click_settings_tab
      expect(f('#quiz_display_points_possible .points_possible')).to include_text '1'

      click_questions_tab
      f('.add_question_group_link').click
      wait_for_ajaximations
      f('.find_bank_link').click
      wait_for_ajaximations
      fj('#find_bank_dialog .bank:visible').click
      submit_dialog('#find_bank_dialog', '.submit_button')
      submit_form('.quiz_group_form')
      wait_for_ajaximations
      click_settings_tab
      expect(f('#quiz_display_points_possible .points_possible')).to include_text '2'
    end

    it 'should check permissions when retrieving question banks', priority: "1", test_id: 201933 do
      @course.account = Account.default
      @course.account.role_overrides.create!(
        permission: 'read_question_banks',
        role: teacher_role,
        enabled: false
      )
      Account.default.reload
      @course.save
      quiz = @course.quizzes.create!(title: 'My Quiz')

      course_bank = AssessmentQuestionBank.create!(context: @course)
      assessment_question_model(bank: course_bank)

      account_bank = AssessmentQuestionBank.create!(context: @course.account)
      assessment_question_model(bank: account_bank)

      get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"
      click_questions_tab

      expect(f("#content")).not_to contain_css('.find_question_link')

      f('.add_question_group_link').click
      expect(f("#content")).not_to contain_css('.find_bank_link')
    end

    it 'should create a question group from a question bank', priority: "1", test_id: 319907 do
      bank = AssessmentQuestionBank.create!(context: @course)
      3.times { assessment_question_model(bank: bank) }

      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      click_questions_tab

      f('.add_question_group_link').click
      wait_for_ajaximations
      group_form = f('#group_top_new .quiz_group_form')

      # give the question group a title
      question_group_title = 'New Question Group'
      group_form.find_element(:name, 'quiz_group[name]').send_keys(question_group_title)

      fln('Link to a Question Bank').click
      wait_for_ajaximations

      # select a question bank
      hover_and_click('li.bank:nth-child(2)')
      fj('div.button-container:nth-child(2) > button:nth-child(1)').click

      message = "Questions will be pulled from the bank: #{bank.title}"
      expect(fj('.assessment_question_bank')).to include_text message
      submit_form(group_form)

      expect(f('#questions .group_top .group_display.name')).to include_text question_group_title
      expect(fj('.assessment_question_bank')).to include_text message
    end

    it 'creates a question group from a question bank from within the Find Quiz Question modal', priority: "1", test_id: 140590 do
      assessment_question_model(bank: AssessmentQuestionBank.create!(context: @course))

      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button
      click_questions_tab
      wait_for_ajaximations

      # open Find Question dialogue
      f('.find_question_link').click
      wait_for_ajaximations

      # select questions from question bank
      f('.select_all_link').click
      wait_for_ajaximations

      # create new quiz question group from selected questions
      question_group_name = 'Quiz Question Group A'
      click_option(ffj('.quiz_group_select'), '[ New Group ]')
      fj('#found_question_group_name').send_keys question_group_name
      fj('#found_question_group_pick').send_keys '1'
      fj('#found_question_group_points').send_keys '1'
      submit_dialog(f('#add_question_group_dialog'), '.submit_button')
      wait_for_ajaximations

      # submit Find Question dialogue
      submit_dialog(f('#find_question_dialog'), '.submit_button')
      wait_for_ajaximations

      expect(f('.quiz_group_form')).to include_text question_group_name
      expect(f('#question_new_question_text').text).to match 'does [a] equal [b] ?'
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

      expect(ffj('.display_question:visible')).to have_size 60
      links = fj('.display_question:visible:last .links')
      hover links
      f('.delete_question_link', links).click
      accept_alert
      expect(ffj('.display_question:visible')).to have_size 59

      @bank.reload
      wait_for_ajaximations
      expect(@bank.assessment_questions.select { |aq| !aq.deleted? }.length).to eq 59
    end

    it 'should allow editing quiz questions that belong to a quiz bank', priority: "1", test_id: 217531 do
      skip_if_chrome('fragile')
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

      open_quiz_edit_form
      click_questions_tab
      hover_and_click("#question_#{@quest1.id} .edit_question_link")
      replace_content(f('.question_form [name=\'question_name\']'), new_name)
      type_in_tiny('.question_content', new_question_text)
      submit_form('.question_form')
      click_save_settings_button

      # verify modifications
      open_quiz_edit_form
      click_questions_tab

      expect(f("#question_#{@quest1.id}")).to include_text new_name
      expect(f("#question_#{@quest1.id}")).to include_text new_question_text
    end

    it "should let teachers view question banks in a soft-concluded course (but not edit)", priority: "2", test_id: 456150 do
      term = Account.default.enrollment_terms.create!
      term.set_overrides(Account.default, 'TeacherEnrollment' => {:end_at => 3.days.ago})
      @course.enrollment_term = term
      @course.save!
      @bank = @course.assessment_question_banks.create!(title: 'Test Bank')

      get "/courses/#{@course.id}/quizzes"

      view_banks_link = f('.view_question_banks')
      expect(view_banks_link).to be_displayed

      expect_new_page_load { view_banks_link.click }

      expect(f("#content")).not_to contain_css('.add_bank_link')
      expect(f("#content")).not_to contain_css('.edit_bank_link')
      expect(f("#content")).not_to contain_css('.delete_bank_link')

      view_bank_link = f("#question_bank_#{@bank.id} a.title")
      expect(view_bank_link).to be_displayed

      expect_new_page_load { view_bank_link.click }
    end

    it "should let account admins view question banks without :manage_assignments (but not edit)", priority: "2", test_id: 456162 do
      user_factory(active_all: true)
      user_session(@user)
      @role = custom_account_role 'weakling', :account => @course.account
      @course.account.role_overrides.create!(:permission => 'read_course_content', :enabled => true, :role => @role)
      @course.account.role_overrides.create!(:permission => 'read_question_banks', :enabled => true, :role => @role)
      @course.account.account_users.create!(user: @user, role: @role)

      @bank = @course.assessment_question_banks.create!(title: 'Test Bank')

      get "/courses/#{@course.id}/quizzes"

      view_banks_link = f('.view_question_banks')
      expect(view_banks_link).to be_displayed

      expect_new_page_load { view_banks_link.click }

      expect(f("#content")).not_to contain_css('.add_bank_link')
      expect(f("#content")).not_to contain_css('.edit_bank_link')
      expect(f("#content")).not_to contain_css('.delete_bank_link')

      view_bank_link = f("#question_bank_#{@bank.id} a.title")
      expect(view_bank_link).to be_displayed

      expect_new_page_load { view_bank_link.click }
    end

    it "should lock out teachers when :read_question_banks is disabled", priority: "2", test_id: 456163 do
      term = Account.default.enrollment_terms.create!
      term.set_overrides(Account.default, 'TeacherEnrollment' => {:end_at => 3.days.ago})
      @course.enrollment_term = term
      @course.save!

      @bank = @course.assessment_question_banks.create!(title: 'Test Bank')

      Account.default.role_overrides.create!(:permission => 'read_question_banks', :role => teacher_role, :enabled => false)
      Account.default.reload

      get "/courses/#{@course.id}/quizzes"
      expect(f("#content")).not_to contain_css('.view_question_banks')

      get "/courses/#{@course.id}/question_banks"
      expect(f('#unauthorized_message')).to be_displayed

      get "/courses/#{@course.id}/question_banks/#{@bank.id}"
      expect(f('#unauthorized_message')).to be_displayed
    end

    it "should move paginated questions in a question bank from one bank to another", priority: "2", test_id: 312864 do
      @context = @course
      source_bank = @course.assessment_question_banks.create!(title: 'Source Bank')
      target_bank = @course.assessment_question_banks.create!(title: 'Target Bank')
      @q = quiz_model
      assessment_question = []
      @quiz_question = []
      answers = [ {'id' => 1}, {'id' => 2}, {'id' => 3} ]
      51.times do |o|
        assessment_question[o] = source_bank.assessment_questions.create!
        @quiz_question.push(@q.quiz_questions.create!(question_data:
                                                   {name: "question #{o}", question_type: 'multiple_choice_question',
                                                   'answers' => answers, points_possible: 1},
                                                      assessment_question: assessment_question[o]))

      end
      get "/courses/#{@course.id}/question_banks/#{source_bank.id}"
      f('.more_questions_link').click
      wait_for_ajaximations
      f("#question_teaser_#{assessment_question[50].id} .move_question_link").click
      f("#question_bank_#{target_bank.id}").click
      f('input[type=checkbox][name=copy]').click
      submit_dialog('#move_question_dialog', '.submit_button')
      wait_for_ajaximations
      refresh_page
      expect(f("#content")).not_to contain_css('.more_questions_link')
      expect(source_bank.assessment_question_count).to eq(50)
      expect(target_bank.assessment_question_count).to eq(1)
    end
  end
end
