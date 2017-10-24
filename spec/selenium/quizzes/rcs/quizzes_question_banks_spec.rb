#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../../helpers/quizzes_common'

describe 'quizzes question banks' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context 'as a teacher' do

    before(:each) do
      course_with_teacher_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
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
  end
end
