# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/accessibility_checker_page"
require_relative "../pages/wiki_page"
require_relative "../support/batch_data_factory"

describe "Accessibility Checker - Table Rules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AccessibilityCheckerPage
  include AccessibilityChecker::BatchDataFactory
  include AccessibilityChecker::WikiPage

  before(:once) do
    course_with_teacher(active_all: true)
    enable_accessibility_checker(@course)
  end

  before do
    user_session(@teacher)
  end

  let(:table_headers_issue_description) { "This table headers isn't set up correctly for screen readers to know which cells it applies to." }

  shared_examples "table rule with selectable fix options" do |fix_applied_message, option_to_apply|
    it "shows fix applied message and enables save and next after applying fix" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option_to_apply)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.footer.save_and_next_enabled?).to be true
    end

    it "displays success view when save and next is clicked" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option_to_apply)
      wizard.apply_fix
      wizard.save_and_next

      expect(wizard.success_view_exists?).to be true
    end

    it "applied fix can be reverted by clicking undo" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option_to_apply)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.undo_button_enabled?).to be true

      wizard.click_undo

      expect(wizard.apply_button_disabled?).to be false
    end
  end

  context "Fixing missing table caption issues" do
    let(:issue_description) { "Tables should include a caption describing the contents of the table." }
    let(:fix_applied_message) { "Caption added" }
    let(:add_caption_label) { "Add caption" }
    let(:valid_caption) { "A descriptive table caption" }

    before(:once) do
      @course.wiki_pages.destroy_all

      @caption_page = create_page_with(@course, :missing_table_caption)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@caption_page.title).click_fix_button
      wait_for_ajaximations
      remediation_wizard.wait_for_form_to_render
    end

    it "displays the correct issue message, caption input, and apply button" do
      wizard = remediation_wizard

      expect(wizard.issue_message_visible?(issue_description)).to be true
      expect(wizard.caption_controls.caption_input.displayed?).to be true
      expect(wizard.apply_button.text).to eq(add_caption_label)
    end

    it "does not apply fix when caption is empty" do
      wizard = remediation_wizard
      wizard.caption_controls.enter_caption(valid_caption)
      wizard.caption_controls.clear_caption

      expect(wizard.caption_controls.caption_required_message_visible?).to be true
      expect(wizard.footer.save_and_next_enabled?).to be false
    end

    it "shows fix applied message and enables save and next after entering caption and applying fix" do
      wizard = remediation_wizard
      wizard.caption_controls.enter_caption(valid_caption)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.footer.save_and_next_enabled?).to be true
    end

    it "displays success view when save and next is clicked" do
      wizard = remediation_wizard
      wizard.caption_controls.enter_caption(valid_caption)
      wizard.apply_fix
      wizard.save_and_next

      expect(wizard.success_view_exists?).to be true
    end

    it "applied fix can be reverted by clicking undo" do
      wizard = remediation_wizard
      wizard.caption_controls.enter_caption(valid_caption)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.undo_button_enabled?).to be true
      expect(wizard.caption_controls.caption_input_disabled?).to be true

      wizard.click_undo

      expect(wizard.apply_button_disabled?).to be false
      expect(wizard.caption_controls.caption_input_disabled?).to be false
      expect(wizard.caption_controls.caption_input_value).to eq(valid_caption)
    end

    it "persists the caption to the actual page content after save" do
      wizard = remediation_wizard
      wizard.caption_controls.enter_caption(valid_caption)
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@caption_page.title).click_resource_name_link

      expect(table_caption_text).to eq(valid_caption)
    end
  end

  context "Fixing missing table headers issues" do
    let(:issue_description) { table_headers_issue_description }
    let(:set_headings_label) { "Set headings" }
    let(:top_row_option) { "The top row" }
    let(:first_column_option) { "The first column" }
    let(:both_option) { "Both" }

    before(:once) do
      @course.wiki_pages.destroy_all

      @headers_page = create_page_with(@course, :table_no_headers)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@headers_page.title).click_fix_button
      wait_for_ajaximations
      remediation_wizard.wait_for_form_to_render
    end

    it "displays the correct issue message, the three fix options, and Set headings button" do
      wizard = remediation_wizard

      expect(wizard.issue_message_visible?(issue_description)).to be true
      expect(wizard.radio_input_controls.option_displayed?(top_row_option)).to be true
      expect(wizard.radio_input_controls.option_displayed?(first_column_option)).to be true
      expect(wizard.radio_input_controls.option_displayed?(both_option)).to be true
      expect(wizard.apply_button.text).to eq(set_headings_label)
    end

    it_behaves_like "table rule with selectable fix options", "Table headings are now set up", "The top row"

    it "fixing with 'The top row' converts the first row cells to header cells" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(top_row_option)
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@headers_page.title).click_resource_name_link

      expect(table_first_row_all_headers?).to be true
    end

    it "fixing with 'The first column' converts the first column cells to header cells" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(first_column_option)
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@headers_page.title).click_resource_name_link

      expect(table_first_column_all_headers?).to be true
    end

    it "fixing with 'Both' converts both rows and columns to header cells" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(both_option)
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@headers_page.title).click_resource_name_link

      expect(table_first_row_all_headers?).to be true
      expect(table_first_column_all_headers?).to be true
    end
  end

  context "Fixing missing table header scope issues" do
    let(:issue_description) { table_headers_issue_description }
    let(:set_heading_scope_label) { "Set heading scope" }
    let(:column_option) { "The column it's in" }
    let(:row_option) { "The row it's in" }
    let(:column_group_option) { "The column group" }
    let(:row_group_option) { "The row group" }

    shared_examples "table header scope fix option" do |option_label, expected_scope|
      it "fixing with '#{option_label}' applies the correct scope to the header cells" do
        wizard = remediation_wizard
        wizard.radio_input_controls.select_option(option_label)
        wizard.apply_fix
        wizard.save_and_next
        wizard.header.click_close_button

        issues_table.find_row_by_resource_name(@scope_page.title).click_resource_name_link

        expect(table_header_scope).to eq(expected_scope)
      end
    end

    before(:once) do
      @course.wiki_pages.destroy_all

      @scope_page = create_page_with(@course, :missing_table_header_scope)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@scope_page.title).click_fix_button
      wait_for_ajaximations
      remediation_wizard.wait_for_form_to_render
    end

    it "displays the correct issue message, the four scope options, and Set heading scope button" do
      wizard = remediation_wizard

      expect(wizard.issue_message_visible?(issue_description)).to be true
      expect(wizard.radio_input_controls.option_displayed?(column_option)).to be true
      expect(wizard.radio_input_controls.option_displayed?(row_option)).to be true
      expect(wizard.radio_input_controls.option_displayed?(column_group_option)).to be true
      expect(wizard.radio_input_controls.option_displayed?(row_group_option)).to be true
      expect(wizard.apply_button.text).to eq(set_heading_scope_label)
    end

    it_behaves_like "table rule with selectable fix options", "Heading scope is now set up.", "The column it's in"

    it_behaves_like "table header scope fix option", "The column it's in", "col"
    it_behaves_like "table header scope fix option", "The row it's in", "row"
    it_behaves_like "table header scope fix option", "The column group", "colgroup"
    it_behaves_like "table header scope fix option", "The row group", "rowgroup"
  end
end
