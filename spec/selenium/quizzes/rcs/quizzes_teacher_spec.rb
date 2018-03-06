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
require_relative '../../helpers/assignment_overrides'
require_relative '../../helpers/files_common'

describe "quizzes" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper
  include FilesCommon

  def add_question_to_group
    f('.add_question_link').click
    wait_for_ajaximations
    question_form = f('.question_form')
    submit_form(question_form)
    wait_for_ajaximations
  end

  context "as a teacher" do

    before(:once) do
      course_with_teacher(active_all: true)
      course_with_student(course: @course, active_enrollment: true)
      @course.update_attributes(:name => 'teacher course')
      @course.save!
      @course.reload
      enable_all_rcs @course.account
    end

    before(:each) do
      user_session(@teacher)
      stub_rcs_config
    end

    it "should create a new question group", priority: "1", test_id: 210060 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button

      click_questions_tab
      f('.add_question_group_link').click
      group_form = f('#questions .quiz_group_form')
      group_form.find_element(:name, 'quiz_group[name]').send_keys('new group')
      replace_content(group_form.find_element(:name, 'quiz_group[question_points]'), '3')
      submit_form(group_form)
      expect(group_form.find_element(:css, '.group_display.name')).to include_text('new group')
    end

    it "should update a question group", priority: "1", test_id: 210061

    it "should not let you exceed the question limit", priority: "2", test_id: 210062 do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button

      click_questions_tab
      f('.add_question_group_link').click
      group_form = f('#questions .quiz_group_form')
      pick_count_field = group_form.find_element(:name, 'quiz_group[pick_count]')
      pick_count = lambda do |count|
        driver.execute_script <<-JS
          var $pickCount = $('#questions .group_top input[name="quiz_group[pick_count]"]');
          $pickCount.focus();
          $pickCount[0].value = #{count.to_s.inspect};
          $pickCount.change();
        JS
      end

      pick_count.call('1001')
      dismiss_alert
      expect(pick_count_field).to have_attribute(:value, "1")

      click_new_question_button # 1 total, ok
      wait_for_ajaximations
      group_form.find_element(:css, '.edit_group_link').click
      pick_count.call('999') # 1000 total, ok

      click_new_question_button # 1001 total, bad
      dismiss_alert

      pick_count.call('1000') # 1001 total, bad
      dismiss_alert
      expect(pick_count_field).to have_attribute(:value, "999")
    end

    describe "insufficient count warnings" do
      it "should show a warning for groups picking too many questions", priority: "2", test_id: 539340 do
        get "/courses/#{@course.id}/quizzes"
        click_new_quiz_button
        click_questions_tab
        f('.add_question_group_link').click
        submit_form('.quiz_group_form')
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to be_displayed

        add_question_to_group
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to_not be_displayed

        f('#questions .edit_group_link').click
        replace_content(f('#questions .group_top input[name="quiz_group[pick_count]"]'), '2')
        submit_form('.quiz_group_form')
        wait_for_ajaximations
        expect(f(".insufficient_count_warning")).to be_displayed

        # save and reload
        expect_new_page_load{ f('.save_quiz_button').click }
        quiz = @course.quizzes.last
        get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

        click_questions_tab
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to be_displayed

        add_question_to_group
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to_not be_displayed
      end

      it "should show a warning for groups picking too many questions from a bank", priority: "2", test_id: 539341 do
        bank = @course.assessment_question_banks.create!
        assessment_question_model(bank: bank)

        get "/courses/#{@course.id}/quizzes"
        click_new_quiz_button
        click_questions_tab
        f('.add_question_group_link').click

        f('.find_bank_link').click
        fj('#find_bank_dialog .bank:visible').click
        submit_dialog('#find_bank_dialog', '.submit_button')
        submit_form('.quiz_group_form')
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to_not be_displayed

        f('#questions .edit_group_link').click
        replace_content(f('#questions .group_top input[name="quiz_group[pick_count]"]'), '2')
        submit_form('.quiz_group_form')
        wait_for_ajaximations
        expect(f(".insufficient_count_warning")).to be_displayed

        # save and reload
        expect_new_page_load{ f('.save_quiz_button').click }
        quiz = @course.quizzes.last
        get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

        click_questions_tab
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to be_displayed

        f('#questions .edit_group_link').click
        replace_content(f('#questions .group_top input[name="quiz_group[pick_count]"]'), '1')
        submit_form('.quiz_group_form')
        wait_for_ajaximations
        expect(f(".insufficient_count_warning")).to_not be_displayed
      end
    end

    it "should mark dropdown questions as answered", priority: "2", test_id: 210067

    def upload_attachment_answer
      f('input[type=file]').send_keys @fullpath
      wait_for_ajaximations
      expect(f('.file-uploaded').text).to be
      expect(f('.list_question, .answered').text).to be
      f('.upload-label').click
      wait_for_ajaximations
    end

    def file_upload_submission_data
      @quiz.reload.quiz_submissions.first.
          submission_data["question_#{@question.id}".to_sym]
    end

    def file_upload_attachment
      @quiz.reload.quiz_submissions.first.attachments.first
    end

    it "should notify a student of extra time given by a moderator", priority: "2", test_id: 210070
  end
end
