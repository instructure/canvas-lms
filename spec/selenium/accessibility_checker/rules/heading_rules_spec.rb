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

describe "Accessibility Checker - Heading Rules", :ignore_js_errors do
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

  context "Fixing heading too long issues" do
    let(:issue_description) { "This heading is very long. Is it meant to be a paragraph?" }
    let(:fix_applied_message) { "Formatted as paragraph" }
    let(:change_to_paragraph_label) { "Change to paragraph" }
    let(:heading_text) { heading_text_for(:heading_too_long) }
    let(:original_heading_present) { heading_present?(issue_heading_level_for(:heading_too_long)) }

    before(:once) do
      @course.wiki_pages.destroy_all

      @heading_page = create_page_with(@course, :heading_too_long)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@heading_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "shows the correct issue description" do
      wizard = remediation_wizard

      expect(wizard.issue_message_visible?(issue_description)).to be true
    end

    it "displays the Change to paragraph button in the wizard" do
      wizard = remediation_wizard

      expect(wizard.apply_button.text).to eq(change_to_paragraph_label)
      expect(wizard.apply_button_disabled?).to be false
    end

    it "enables save and next button after clicking Change to paragraph" do
      wizard = remediation_wizard
      wizard.apply_fix

      expect(wizard.footer.save_and_next_enabled?).to be true
    end

    it "displays success view when save and next button is clicked" do
      wizard = remediation_wizard
      wizard.apply_fix
      wizard.save_and_next

      expect(wizard.success_view_exists?).to be true
    end

    it "applied fix can be reverted by clicking undo" do
      wizard = remediation_wizard
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.undo_button_enabled?).to be true

      wizard.click_undo

      expect(wizard.apply_button.text).to eq(change_to_paragraph_label)
      expect(wizard.apply_button_disabled?).to be false
    end

    it "persists the heading converted to paragraph after save" do
      wizard = remediation_wizard
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@heading_page.title).click_resource_name_link

      expect(original_heading_present).to be false
      expect(converted_paragraph.text).to include(heading_text)
    end
  end

  shared_examples "heading rule with selectable fix options" do |option1_label, option2_label|
    let(:reformat_label) { "Reformat" }
    let(:converted_paragraph_present) { converted_paragraph.displayed? }

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@heading_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "shows the correct issue description" do
      wizard = remediation_wizard

      expect(wizard.issue_message_visible?(issue_description)).to be true
    end

    it "displays the correct fix options" do
      wizard = remediation_wizard

      expect(wizard.radio_input_controls.option_displayed?(option1_label)).to be true
      expect(wizard.radio_input_controls.option_displayed?(option2_label)).to be true
    end

    it "fixes the issue by selecting '#{option1_label}' option and enables save and next" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option1_label)
      wizard.apply_fix

      expect(wizard.footer.save_and_next_enabled?).to be true
    end

    it "fixes the issue by selecting '#{option2_label}' option and enables save and next" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option2_label)
      wizard.apply_fix

      expect(wizard.footer.save_and_next_enabled?).to be true
    end

    it "displays success view when save and next button is clicked" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option1_label)
      wizard.apply_fix
      wizard.save_and_next

      expect(wizard.success_view_exists?).to be true
    end

    it "applied fix can be reverted by clicking undo" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option1_label)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.undo_button_enabled?).to be true

      wizard.click_undo

      expect(wizard.apply_button.text).to eq(reformat_label)
      expect(wizard.apply_button_disabled?).to be false
    end

    it "persists '#{option1_label}' fix to page content after save" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option1_label)
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@heading_page.title).click_resource_name_link

      expect(original_heading_present).to be false
      expect(option1_result_present).to be true
    end

    it "persists '#{option2_label}' fix to page content after save" do
      wizard = remediation_wizard
      wizard.radio_input_controls.select_option(option2_label)
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@heading_page.title).click_resource_name_link

      expect(original_heading_present).to be false
      expect(converted_paragraph_present).to be true
    end
  end

  context "Fixing headings start at H2 issues" do
    let(:issue_description) do
      "This text is styled as a Heading 1, but there should only be one H1 on a web page — the page title. " \
        "Use Heading 2 or lower (H2, H3, etc.) for your content headings instead."
    end
    let(:fix_applied_message) { "Reformatted" }
    let(:original_heading_present) { body_heading_present?(issue_heading_level_for(:heading_starts_at_h2), heading_text_for(:heading_starts_at_h2)) }
    let(:option1_result_present) { heading_present?(corrected_heading_level_for(:heading_starts_at_h2)) }

    before(:once) do
      @course.wiki_pages.destroy_all

      @heading_page = create_page_with(@course, :heading_starts_at_h2)
    end

    it_behaves_like "heading rule with selectable fix options", "Change heading level to Heading 2", "Turn into a paragraph"
  end

  context "Fixing heading sequence issues" do
    let(:issue_description) do
      "This heading is more than one level below the previous heading." \
        "Heading levels should follow a logical order, for example Heading 2, then H3, then H4."
    end
    let(:fix_applied_message) { "Heading hierarchy is now correct" }
    let(:original_heading_present) { heading_present?(issue_heading_level_for(:heading_sequence)) }
    let(:option1_result_present) { heading_present?(corrected_heading_level_for(:heading_sequence)) }

    before(:once) do
      @course.wiki_pages.destroy_all

      @heading_page = create_page_with(@course, :heading_sequence)
    end

    it_behaves_like "heading rule with selectable fix options", "Fix heading level", "Turn into a paragraph"
  end
end
