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

describe "Accessibility Checker - Misformatted List Rule", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AccessibilityCheckerPage
  include AccessibilityChecker::BatchDataFactory
  include AccessibilityChecker::WikiPage

  let(:issue_description) { "This looks like a list but isn't formatted as one." }
  let(:fix_applied_message) { "List is now formatted correctly." }
  let(:reformat_button_label) { "Reformat" }

  before(:once) do
    course_with_teacher(active_all: true)
    enable_accessibility_checker(@course)
  end

  before do
    user_session(@teacher)
  end

  shared_examples "persists reformatted list" do |list_type, expected_list_tag|
    let(:reformatted_list_items) { content_list_items(expected_list_tag) }

    it "persists the reformatted #{list_type} list to the actual page content after save" do
      issues_table.find_row_by_resource_name(list_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(list_page.title).click_resource_name_link

      expect(reformatted_list_items.length).to eq(expected_item_count)
    end
  end

  context "Fixing misformatted list issues" do
    before(:once) do
      @course.wiki_pages.destroy_all

      @ordered_list_page = create_page_with(@course, :misformatted_ordered_list)
      @unordered_list_page = create_page_with(@course, :misformatted_unordered_list)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@ordered_list_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "shows the correct issue description" do
      wizard = remediation_wizard

      expect(wizard.issue_message_visible?(issue_description)).to be true
    end

    it "displays the Reformat button in the wizard" do
      wizard = remediation_wizard

      expect(wizard.apply_button.text).to eq(reformat_button_label)
      expect(wizard.apply_button_disabled?).to be false
    end

    it "enables save and next button after clicking Reformat" do
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

      expect(wizard.apply_button.text).to eq(reformat_button_label)
      expect(wizard.apply_button_disabled?).to be false
    end

    it_behaves_like "persists reformatted list", "ordered", "ol" do
      let(:list_page) { @ordered_list_page }
      let(:expected_item_count) { list_item_count_for(:misformatted_ordered_list) }
    end

    it_behaves_like "persists reformatted list", "unordered", "ul" do
      let(:list_page) { @unordered_list_page }
      let(:expected_item_count) { list_item_count_for(:misformatted_unordered_list) }
    end
  end
end
