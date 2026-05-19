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

describe "Accessibility Checker - Contrast Rules", :ignore_js_errors do
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

  def hex_to_rgb(hex_color)
    hex = hex_color.delete_prefix("#")
    r, g, b = hex.scan(/../).map { |h| h.to_i(16) }
    "rgb(#{r}, #{g}, #{b})"
  end

  shared_examples "low contrast rule" do
    let(:issue_description) { "Use a color that provides more contrast" }
    let(:fix_applied_message) { "Color changed" }
    let(:apply_button_label) { "Change text color" }
    let(:insufficient_contrast_message) { "Insufficient contrast ratio" }
    let(:expected_color_style) { "color: #{hex_to_rgb(passing_color)}" }

    it "displays the correct issue message, color picker, and Change text color button" do
      wizard = remediation_wizard

      expect(wizard.issue_message_visible?(issue_description)).to be true
      expect(wizard.color_picker_controls.color_input.displayed?).to be true
      expect(wizard.apply_button.text).to eq(apply_button_label)
    end

    it "shows fix applied message and enables save and next after applying a passing color" do
      wizard = remediation_wizard
      wizard.color_picker_controls.enter_color(passing_color)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.footer.save_and_next_enabled?).to be true
    end

    it "displays success view when save and next is clicked" do
      wizard = remediation_wizard
      wizard.color_picker_controls.enter_color(passing_color)
      wizard.apply_fix
      wizard.save_and_next

      expect(wizard.success_view_exists?).to be true
    end

    it "applied fix can be reverted by clicking undo" do
      wizard = remediation_wizard
      wizard.color_picker_controls.enter_color(passing_color)
      wizard.apply_fix

      expect(wizard.fix_applied_message_visible?(fix_applied_message)).to be true
      expect(wizard.undo_button_enabled?).to be true

      wizard.click_undo

      expect(wizard.apply_button_disabled?).to be false
      expect(wizard.color_picker_controls.color_value).to eq(passing_color)
      expect(wizard.footer.save_and_next_enabled?).to be false
    end

    it "fix is rejected when the applied color still fails the threshold" do
      wizard = remediation_wizard
      wizard.color_picker_controls.enter_color(failing_color)
      wizard.apply_fix

      expect(wizard.issue_message_visible?(insufficient_contrast_message)).to be true
      expect(wizard.footer.save_and_next_enabled?).to be false
    end

    it "clearing the color input shows a required field validation message and save and next remains disabled" do
      wizard = remediation_wizard
      wizard.color_picker_controls.clear_color

      expect(wizard.color_picker_controls.required_message_visible?).to be true
      expect(wizard.footer.save_and_next_enabled?).to be false
    end

    it "persists the new text color to the actual page content after save" do
      wizard = remediation_wizard
      wizard.color_picker_controls.enter_color(passing_color)
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@contrast_page.title).click_resource_name_link

      expect(text_color_style).to include(expected_color_style)
    end
  end

  context "Fixing small text contrast issues" do
    let(:passing_color) { "#767676" }
    let(:failing_color) { "#777777" }

    before(:once) do
      @course.wiki_pages.destroy_all

      @contrast_page = create_page_with(@course, :small_text_contrast)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@contrast_page.title).click_fix_button
      wait_for_ajaximations
      remediation_wizard.wait_for_form_to_render
    end

    it_behaves_like "low contrast rule"
  end

  context "Fixing large text contrast issues" do
    let(:passing_color) { "#949494" }
    let(:failing_color) { "#969696" }

    before(:once) do
      @course.wiki_pages.destroy_all

      @contrast_page = create_page_with(@course, :large_text_contrast)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@contrast_page.title).click_fix_button
      wait_for_ajaximations
      remediation_wizard.wait_for_form_to_render
    end

    it_behaves_like "low contrast rule"
  end
end
