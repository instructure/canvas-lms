# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/quizzes_common"
require_relative "../helpers/assignment_overrides"
require_relative "../helpers/files_common"
require_relative "../helpers/admin_settings_common"
require_relative "../rcs/pages/rce_next_page"
require_relative "../helpers/wiki_and_tiny_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "page_objects/quizzes_edit_page"

describe "creating a quiz" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper
  include FilesCommon
  include AdminSettingsCommon
  include RCENextPage
  include WikiAndTinyCommon
  include ItemsAssignToTray
  include QuizzesEditPage

  context "as a teacher" do
    before do
      stub_rcs_config
      course_with_teacher_logged_in(course_name: "Test Course", active_all: true)
    end

    it "saves and publishes a new quiz", :xbrowser, custom_timeout: 30, priority: "1" do
      @quiz = course_quiz
      open_quiz_edit_form

      expect(f("#quiz-draft-state")).to be_displayed

      expect_new_page_load { f(".save_and_publish").click }
      expect(f("#quiz-publish-link.btn-published")).to be_displayed

      # Check that the list of quizzes is also updated
      get "/courses/#{@course.id}/quizzes"
      expect(f("#summary_quiz_#{@quiz.id} .icon-publish")).to be_displayed
    end

    context "when on the quizzes index page" do
      before do
        get "/courses/#{@course.id}/quizzes"
      end

      def create_new_quiz
        expect_new_page_load do
          f(".new-quiz-link").click
        end
      end

      it "creates a quiz directly from the index page", priority: "1" do
        expect do
          create_new_quiz
        end.to change { Quizzes::Quiz.count }.by(1)
      end

      it "redirects to the correct quiz edit form", priority: "2" do
        create_new_quiz
        # check url
        expect(driver.current_url).to match %r{/courses/\d+/quizzes/#{Quizzes::Quiz.last.id}/edit}
      end

      # TODO: remove this from test-rail, this test is redundant
      it "creates and previews a new quiz", priority: "1"
    end

    it "inserts files using the rich content editor", priority: "1" do
      filename = "b_file.txt"
      txt_files = ["some test file", filename]
      txt_files.map do |text_file|
        file = @course.attachments.create!(display_name: text_file, uploaded_data: default_uploaded_data)
        file.context = @course
        file.save!
      end
      @quiz = course_quiz
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      add_file_to_rce_next
      submit_form(".form-actions")
      wait_for_ajax_requests
      expect(fln("text_file.txt")).to be_displayed
    end
  end

  context "post to sis default setting" do
    before do
      account_model
      @account.set_feature_flag! "post_grades", "on"
      course_with_teacher_logged_in(active_all: true, account: @account)
    end

    it "defaults to post grades if account setting is enabled", custom_timeout: 30 do
      @account.settings[:sis_default_grade_export] = { locked: false, value: true }
      @account.save!

      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load { f(".new-quiz-link").click }

      expect(is_checked("#quiz_post_to_sis")).to be_truthy
    end

    it "does not default to post grades if account setting is not enabled", custom_timeout: 30 do
      get "/courses/#{@course.id}/quizzes"
      expect_new_page_load { f(".new-quiz-link").click }
      expect(is_checked("#quiz_post_to_sis")).to be_falsey
    end

    describe "upon save" do
      let(:title) { "My Title" }
      let(:error_text) { "'Please add a due date'" }
      let(:error) { fj(".error_box div:contains(#{error_text})") }
      let(:due_date) { Time.zone.now }
      let(:due_date_input_fields) { ff(".DueDateInput") }
      let(:sync_sis_button) { f("#quiz_post_to_sis") }
      let(:section_to_set) { "Section B" }

      def new_quiz
        @quiz = course_quiz
        @quiz.post_to_sis = "1"
        Timecop.freeze(7.days.ago) do
          @quiz.due_at = Time.zone.now
        end
        @quiz.save!
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      end

      def submit_blocked_with_errors
        click_quiz_save_button
        expect(error).not_to be_nil
      end

      def last_override(name)
        select_last_override_section(name)
        Timecop.freeze(5.days.from_now) do
          last_due_at_element.send_keys(Time.zone.now)
        end
      end

      before do
        turn_on_sis_settings(@account)
        @account.settings[:sis_require_assignment_due_date] = { value: true }
        @account.save!
      end

      context "with due dates" do
        it "does not block" do
          new_quiz
          submit_page
        end

        describe "with assign to cards embedded in page" do
          it "blocks when enabled", :ignore_js_errors do
            skip("LX-1858: Tray is not using the checkbox value")
            @course.course_sections.create!(name: section_to_set)
            new_quiz

            expect(assign_to_date_and_time[0].text).to include("Please add a due date")

            update_due_date(0, format_date_for_view(due_date, "%-m/%-d/%Y"))
            update_due_time(0, "11:59 PM")

            click_quiz_save_button
            expect(driver.current_url).to include("edit")
          end

          it "does not block when disabled" do
            new_quiz
            set_value(sync_sis_button, false)

            submit_page
          end

          it "blocks with base set with override not", :ignore_js_errors do
            skip("LX-1858: Tray is not using the checkbox value")
            @course.course_sections.create!(name: section_to_set)
            new_quiz

            expect(assign_to_date_and_time[0].text).to include("Please add a due date")

            update_due_date(0, format_date_for_view(due_date, "%-m/%-d/%Y"))
            update_due_time(0, "11:59 PM")

            click_add_assign_to_card

            expect(assign_to_date_and_time[3].text).to include("Please add a due date")

            select_module_item_assignee(1, section_to_set)
            update_due_date(0, format_date_for_view(due_date, "%-m/%-d/%Y"))
            update_due_time(0, "11:59 PM")

            click_quiz_save_button
            expect(driver.current_url).to include("edit")
          end

          it "does not block with base set with override not when disabled", :ignore_js_errors do
            skip("LX-1858: Tray is not using the checkbox value")
            @course.course_sections.create!(name: section_to_set)
            new_quiz
            set_value(sync_sis_button, false)

            click_add_assign_to_card
            select_module_item_assignee(1, section_to_set)

            click_quiz_save_button
            expect(driver.current_url).to include("edit")
          end
        end
      end
    end
  end
end
