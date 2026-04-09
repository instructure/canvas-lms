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
require_relative "../support/batch_data_factory"

describe "Accessibility Checker - Alt Text Related Rules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AccessibilityCheckerPage
  include AccessibilityChecker::BatchDataFactory

  let(:fix_applied_message) { "Alt text updated" }
  let(:valid_alt_text_value) { "A descriptive alt text" }

  before(:once) do
    course_with_teacher(active_all: true)
    enable_accessibility_checker(@course)
  end

  before do
    user_session(@teacher)
  end

  context "Common alt text rule behavior" do
    before(:once) do
      @course.wiki_pages.destroy_all

      @image_page = create_page_with(@course, :missing_alt_text)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@image_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "displays alt text input" do
      wizard = remediation_wizard

      expect(wizard.alt_text_controls.alt_text_input.displayed?).to be true
    end

    it "enables save and next button after applying fix" do
      wizard = remediation_wizard
      wizard.alt_text_controls.enter_alt_text(valid_alt_text_value)
      wizard.apply_fix

      expect(wizard.footer.save_and_next_enabled?).to be true
    end

    it "displays success view when save and next button is clicked" do
      wizard = remediation_wizard
      wizard.alt_text_controls.enter_alt_text(valid_alt_text_value)

      wizard.apply_fix
      wizard.save_and_next

      expect(wizard.success_view_exists?).to be true
    end

    it "disables alt text input when image is marked as decorative" do
      wizard = remediation_wizard

      wizard.alt_text_controls.mark_as_decorative

      expect(wizard.alt_text_controls.alt_text_input_disabled?).to be true
    end

    it "re-enables alt text input when unchecking decorative" do
      wizard = remediation_wizard

      wizard.alt_text_controls.mark_as_decorative
      wizard.alt_text_controls.unmark_as_decorative

      expect(wizard.alt_text_controls.alt_text_input_disabled?).to be false
    end

    it "clears previously entered alt text when marking as decorative" do
      wizard = remediation_wizard
      wizard.alt_text_controls.enter_alt_text(valid_alt_text_value)

      wizard.alt_text_controls.mark_as_decorative

      expect(wizard.alt_text_controls.alt_text_input_value).to be_empty
    end

    it "applied fix can be reverted by clicking undo" do
      wizard = remediation_wizard
      wizard.alt_text_controls.enter_alt_text(valid_alt_text_value)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.undo_button_enabled?).to be true
      expect(wizard.alt_text_controls.alt_text_input_disabled?).to be true

      wizard.click_undo

      expect(wizard.apply_button_disabled?).to be false
      expect(wizard.alt_text_controls.alt_text_input_disabled?).to be false
      expect(wizard.alt_text_controls.alt_text_input_value).to eq(valid_alt_text_value)
    end
  end

  context "Fixing missing alt text issues" do
    before(:once) do
      @course.wiki_pages.destroy_all

      @image_page = create_page_with(@course, :missing_alt_text)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@image_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "does not apply fix when alt text is empty" do
      wizard = remediation_wizard
      wizard.alt_text_controls.enter_alt_text(valid_alt_text_value)
      wizard.alt_text_controls.clear_alt_text

      expect(wizard.alt_text_controls.alt_text_required_message_visible?).to be true
      expect(wizard.footer.save_and_next_enabled?).to be false
    end

    it "persists the alt text to the actual page content after save" do
      wizard = remediation_wizard
      wizard.alt_text_controls.enter_alt_text(valid_alt_text_value)
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@image_page.title).click_resource_name_link

      saved_alt_text = f(".show-content img").attribute("alt")
      expect(saved_alt_text).to eq(valid_alt_text_value)
    end
  end

  context "Fixing alt text too long issues" do
    let(:too_long_alt_text) { "A" * 201 }

    before(:once) do
      @course.wiki_pages.destroy_all

      @image_page = create_page_with(@course, :alt_text_too_long)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@image_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "does not apply fix when alt text exceeds 200 characters" do
      wizard = remediation_wizard
      wizard.alt_text_controls.clear_alt_text
      wizard.alt_text_controls.enter_alt_text(too_long_alt_text)

      expect(wizard.alt_text_controls.alt_text_too_long_message_visible?).to be true
      expect(wizard.footer.save_and_next_enabled?).to be false
    end

    it "applies fix when the provided alt text is below 200 characters" do
      wizard = remediation_wizard
      wizard.alt_text_controls.clear_alt_text
      wizard.alt_text_controls.enter_alt_text(valid_alt_text_value)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.footer.save_and_next_enabled?).to be true
    end
  end

  context "Fixing alt text is filename issues" do
    before(:once) do
      @course.wiki_pages.destroy_all

      @image_page = create_page_with(@course, :alt_text_is_filename)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@image_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "does not apply fix when alt text is still a filename" do
      wizard = remediation_wizard
      wizard.apply_fix

      expect(wizard.alt_text_controls.alt_text_filename_message_visible?).to be true
      expect(wizard.footer.save_and_next_enabled?).to be false
    end

    it "applies fix when alt text is replaced with a non-filename value" do
      wizard = remediation_wizard
      wizard.alt_text_controls.clear_alt_text
      wizard.alt_text_controls.enter_alt_text(valid_alt_text_value)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.footer.save_and_next_enabled?).to be true
    end
  end
end
