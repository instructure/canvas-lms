# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "../helpers/assignments_common"
require_relative "../helpers/public_courses_context"
require_relative "../helpers/files_common"
require_relative "../helpers/admin_settings_common"
require_relative "../../helpers/selective_release_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "../assignments/page_objects/assignment_create_edit_page"

describe "assignments sync to sis" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include AssignmentsCommon
  include AdminSettingsCommon
  include CustomScreenActions
  include CustomSeleniumActions
  include SelectiveReleaseCommon
  include ItemsAssignToTray

  # NOTE: due date testing can be found in assignments_overrides_spec

  context "as a teacher" do
    before(:once) do
      differentiated_modules_off
      @teacher = user_with_pseudonym
      course_with_teacher({ user: @teacher, active_course: true, active_enrollment: true })
      @course.start_at = nil
      @course.save!
      @course.require_assignment_group
    end

    before do
      create_session(@pseudonym)
      account_model
      turn_on_sis
      new_assignment
    end

    let(:name_length_limit) { 10 }
    let(:invalid_name) { "Name Assignment Too Long" }
    let(:valid_name) { "Name" }
    let(:points) { "10" }
    let(:differentiate) { false }
    let(:due_date) { 3.years.from_now }
    let(:due_date_valid) { "#{format_date_for_view(3.years.from_now)} at 11:59pm" }
    let(:short_date) { format_date_for_view(3.years.from_now) }
    let(:error) { "" }
    let(:settings_enable) { {} }
    let(:name_length_invalid) { false }

    def differentiate_assignment
      @course.course_sections.create!(name: "Section A")
      @course.course_sections.create!(name: "Section B")
    end

    def new_assignment
      course_with_teacher_logged_in(active_all: true, account: @account)
      differentiate_assignment if differentiate
      get "/courses/#{@course.id}/assignments/new"
      title_text = name_length_invalid ? invalid_name : valid_name
      set_value(f("#assignment_name"), title_text)
      set_value(f("#assignment_points_possible"), points)
      f("#assignment_text_entry").click
    end

    def turn_on_sis
      turn_on_sis_settings(@account)
      turn_on_limitations
    end

    def turn_on_limitations
      @account.settings.merge!(settings_enable)
      @account.save!
    end

    def submit_blocked_with_errors
      f("#edit_assignment_form .btn-primary[type=submit]").click
      expect(errors).to include(error)
    end

    def errors
      ff(".error_box").map(&:text)
    end

    def due_date_input_fields
      ff(".DueDateInput")
    end

    def check_due_date_table(section, due_date = "-")
      row_elements = f(".assignment_dates").find_elements(:tag_name, "tr")
      section_row = row_elements.detect { |i| i.text.include?(section) }
      expect(section_row).not_to be_nil
      expect(section_row.text.split("\n").first).to eq due_date
    end

    def click_assign_to_dropdown_option(date_container_el, section_name_given)
      input_el = f('[aria-label^="Add students"]', date_container_el)
      list_id = input_el.attribute("aria-owns")
      input_el.click
      f('[id="' + list_id + '"] [value="' + section_name_given + '"]', date_container_el).click
    end

    def assign_to_section(date_container, section_name)
      scroll_to(f('[aria-label^="Add students"]', date_container))
      click_assign_to_dropdown_option(date_container, section_name)
    end

    context "assignment name length" do
      let(:error) { "Name is too long, must be under 11 characters" }

      let(:name_length_invalid) { true }
      let(:settings_enable) { length_settings }

      def length_settings
        {
          sis_assignment_name_length: { value: true },
          sis_assignment_name_length_input: { value: name_length_limit.to_s }
        }
      end

      it "validates name length while sis is on" do
        submit_blocked_with_errors
        set_value(f("#assignment_name"), valid_name)
        submit_assignment_form
        expect(f("h1.title")).to include_text(valid_name)
      end

      it "does not validate when sis is off" do
        f("#assignment_post_to_sis").click
        submit_assignment_form
        expect(f("h1.title")).to include_text(invalid_name)
      end
    end

    context "due date required" do
      let(:error) { "Please add a due date" }
      let(:settings_enable) { { sis_require_assignment_due_date: { value: true } } }

      context "with selective release flags on" do
        before(:once) do
          differentiated_modules_on
        end

        it "validates due date while sis is on", :ignore_js_errors do
          # LX-1857: Does not show any error, but not submits, we should verify an error here
          AssignmentCreateEditPage.save_assignment

          AssignmentCreateEditPage.click_manage_assign_to_button

          wait_for_assign_to_tray_spinner
          keep_trying_until { expect(item_tray_exists?).to be_truthy }

          expect(assign_to_date_and_time[0].text).to include("Please add a due date")

          update_due_date(0, format_date_for_view(due_date, "%-m/%-d/%Y"))
          update_due_time(0, "11:59 PM")
          click_save_button("Apply")
          keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

          AssignmentCreateEditPage.save_assignment

          check_due_date_table("Everyone", short_date)
        end

        it "does not validate when sis is off" do
          AssignmentCreateEditPage.select_post_to_sis_checkbox
          AssignmentCreateEditPage.save_assignment

          check_due_date_table("Everyone")
        end

        it "validates due date when user checks/unchecks the box", :ignore_js_errors do
          # LX-1857: Does not show any error, but not submits, we should verify an error here
          AssignmentCreateEditPage.save_assignment

          AssignmentCreateEditPage.select_post_to_sis_checkbox
          AssignmentCreateEditPage.click_manage_assign_to_button

          wait_for_assign_to_tray_spinner
          keep_trying_until { expect(item_tray_exists?).to be_truthy }

          expect(assign_to_date_and_time[0].text).not_to include("Please add a due date")

          click_save_button("Apply")
          keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

          AssignmentCreateEditPage.select_post_to_sis_checkbox
          AssignmentCreateEditPage.click_manage_assign_to_button

          wait_for_assign_to_tray_spinner
          keep_trying_until { expect(item_tray_exists?).to be_truthy }

          expect(assign_to_date_and_time[0].text).to include("Please add a due date")

          update_due_date(0, format_date_for_view(due_date, "%-m/%-d/%Y"))
          update_due_time(0, "11:59 PM")
          click_save_button("Apply")
          keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

          AssignmentCreateEditPage.save_assignment

          check_due_date_table("Everyone", short_date)
        end

        describe "differentiated assignment" do
          let(:differentiate) { true }
          let(:section_to_set) { "Section B" }

          it "checks each due date when on", :ignore_js_errors do
            # LX-1857: Does not show any error, but not submits, we should verify an error here
            AssignmentCreateEditPage.save_assignment

            AssignmentCreateEditPage.click_manage_assign_to_button

            wait_for_assign_to_tray_spinner
            keep_trying_until { expect(item_tray_exists?).to be_truthy }

            expect(assign_to_date_and_time[0].text).to include("Please add a due date")

            update_due_date(0, format_date_for_view(due_date, "%-m/%-d/%Y"))
            update_due_time(0, "11:59 PM")
            click_add_assign_to_card

            expect(assign_to_date_and_time[3].text).to include("Please add a due date")

            select_module_item_assignee(1, section_to_set)
            update_due_date(1, format_date_for_view(due_date, "%-m/%-d/%Y"))
            update_due_time(1, "11:59 PM")
            click_save_button("Apply")
            keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

            AssignmentCreateEditPage.save_assignment

            check_due_date_table(section_to_set, short_date)
          end

          it "checks due date when first add cards then fill fields", :ignore_js_errors do
            # LX-1857: Does not show any error, but not submits, we should verify an error here
            AssignmentCreateEditPage.save_assignment

            AssignmentCreateEditPage.click_manage_assign_to_button

            wait_for_assign_to_tray_spinner
            keep_trying_until { expect(item_tray_exists?).to be_truthy }

            expect(assign_to_date_and_time[0].text).to include("Please add a due date")

            click_add_assign_to_card

            update_due_date(0, format_date_for_view(due_date, "%-m/%-d/%Y"))
            update_due_time(0, "11:59 PM")

            expect(assign_to_date_and_time[3].text).to include("Please add a due date")

            select_module_item_assignee(1, section_to_set)
            update_due_date(1, format_date_for_view(due_date, "%-m/%-d/%Y"))
            update_due_time(1, "11:59 PM")
            click_save_button("Apply")
            keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

            AssignmentCreateEditPage.save_assignment

            check_due_date_table(section_to_set, short_date)
          end

          it "does not check when sis is off", :ignore_js_errors do
            skip("LX-1856: Tray is not using the checkbox value")
            AssignmentCreateEditPage.select_post_to_sis_checkbox
            AssignmentCreateEditPage.click_manage_assign_to_button

            wait_for_assign_to_tray_spinner
            keep_trying_until { expect(item_tray_exists?).to be_truthy }
            click_add_assign_to_card
            select_module_item_assignee(1, section_to_set)
            click_save_button("Apply")
            keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

            AssignmentCreateEditPage.save_assignment

            check_due_date_table(section_to_set)
            check_due_date_table("Everyone else")
          end
        end
      end

      context "with selective release flags off" do
        before(:once) do
          differentiated_modules_off
        end

        it "validates due date while sis is on" do
          submit_blocked_with_errors
          set_value(due_date_input_fields.first, due_date_valid)
          submit_assignment_form
          check_due_date_table("Everyone", short_date)
        end

        it "does not validate when sis is off" do
          f("#assignment_post_to_sis").click
          submit_assignment_form
          check_due_date_table("Everyone")
        end

        describe "differentiated assignment" do
          let(:differentiate) { true }
          let(:section_to_set) { "Section B" }

          before do
            assign_section_due_date
          end

          def assign_section_due_date
            f("#add_due_date").click
            due_date_fields = ff(".Container__DueDateRow-item")
            assign_to_section(due_date_fields.last, section_to_set)
          end

          it "checks each due date when on" do
            submit_blocked_with_errors
            due_date_input_fields.each { |h| set_value(h, due_date_valid) }
            f("#edit_assignment_form .btn-primary[type=submit]").click
            check_due_date_table(section_to_set, short_date)
          end

          it "does not check when sis is off" do
            f("#assignment_post_to_sis").click
            submit_assignment_form
            check_due_date_table(section_to_set)
            check_due_date_table("Everyone else")
          end
        end
      end
    end

    context "when on index page" do
      let(:assignment_name) { "Test Assignment" }
      let(:settings_enable) { { sis_require_assignment_due_date: { value: true } } }
      let(:expected_date) { format_date_for_view(1.month.ago) }
      let(:assignment_id) { @assignment.id }
      let(:assignment_entry) { f("#assignment_#{assignment_id}") }
      let(:post_to_sis_button) { f(".post-to-sis-status", assignment_entry) }
      let(:due_date_error) { f("#flash_message_holder") }
      let(:sis_state_text) { f(".icon-post-to-sis", post_to_sis_button).attribute(:alt) }
      let(:due_date_display) { true }
      let(:sis_state) { due_date_display ? "disabled" : "enabled" }
      let(:set_date) { due_date_display ? nil : 1.day.ago }
      let(:params) { { name: assignment_name } }
      let(:type) { @course.assignments }

      before do
        account_model
        turn_on_sis
      end

      def create_hash(due_date = nil)
        { post_to_sis: false, points_possible: 10 }.merge(due_date_params(due_date))
      end

      def create_assignment(due_date = nil)
        @assignment = type.create(create_hash(due_date).merge(params))
        @assignment.publish! unless @assignment.published?
      end

      def due_date_params(due_date = nil)
        due_date ? { due_at: due_date } : { due_at: nil, only_visible_to_overrides: true }
      end

      def override_create(section_name, due_date = Timecop.freeze(1.day.ago))
        section = @course.course_sections.create! name: section_name

        @assignment.assignment_overrides.create! do |override|
          override.set = section
          override.due_at = due_date
          override.due_at_overridden = true
        end
      end

      def click_sync_to_sis
        post_to_sis_button.click
        wait_for_ajaximations
      end

      def validate
        get "/courses/#{@course.id}/assignments"
        click_sync_to_sis
        expect(due_date_error.displayed?).to be due_date_display
        expect(sis_state_text).to include(sis_state)
      end

      describe "when there are due dates" do
        it "where there are no overrides" do
          create_assignment(set_date)
          validate
        end

        it "when there are overrides and no base" do
          create_assignment
          override_create("A", set_date)
          validate
        end

        it "when there is a base and overrides" do
          create_assignment(expected_date)
          override_create("A", set_date)
          validate
        end
      end

      describe "when there are not due dates" do
        let(:due_date_display) { false }

        it "where there are no overrides" do
          create_assignment(set_date)
          validate
        end

        it "when there are overrides and no base" do
          create_assignment
          override_create("A", set_date)
          validate
        end

        it "when there is a base and overrides" do
          create_assignment(expected_date)
          override_create("A", set_date)
          validate
        end
      end

      describe "when due dates for quizzes" do
        let(:assignment_id) { @assignment.assignment.id }
        let(:type) { @course.quizzes }
        let(:assignment_group) { @course.assignment_groups.create!(name: "default") }
        let(:params) { { title: assignment_name, assignment_group: } }

        it "when there are no overrides" do
          create_assignment(set_date)
          validate
        end

        it "when there are overrides and no base" do
          create_assignment
          override_create("A", set_date)
          validate
        end

        it "when there is a base and overrides" do
          create_assignment(expected_date)
          override_create("A", set_date)
          validate
        end
      end
    end
  end
end
