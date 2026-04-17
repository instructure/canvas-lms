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

describe "Accessibility Checker - Adjacent Links Rule", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AccessibilityCheckerPage
  include AccessibilityChecker::BatchDataFactory
  include AccessibilityChecker::WikiPage

  let(:issue_description) { "These are two links that go to the same place. Turn them into one link to avoid repetition." }
  let(:fix_applied_message) { "Links merged" }
  let(:merge_button_label) { "Merge links" }
  let(:first_link_text) { "First link" }
  let(:second_link_text) { "Second link" }

  before(:once) do
    course_with_teacher(active_all: true)
    enable_accessibility_checker(@course)
  end

  before do
    user_session(@teacher)
  end

  context "Fixing adjacent links issues" do
    let(:link_count) { content_links.length }
    let(:merged_link_text) { content_link.text }

    before(:once) do
      @course.wiki_pages.destroy_all

      @adjacent_links_page = create_page_with(@course, :adjacent_links)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@adjacent_links_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "shows the correct issue description" do
      wizard = remediation_wizard

      expect(wizard.issue_message_visible?(issue_description)).to be true
    end

    it "displays the Merge links button in the wizard" do
      wizard = remediation_wizard

      expect(wizard.apply_button.text).to eq(merge_button_label)
      expect(wizard.apply_button_disabled?).to be false
    end

    it "enables save and next button after clicking Merge links" do
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

      expect(wizard.apply_button.text).to eq(merge_button_label)
      expect(wizard.apply_button_disabled?).to be false
    end

    it "persists the merged link to the actual page content after save" do
      wizard = remediation_wizard
      wizard.apply_fix
      wizard.save_and_next
      wizard.header.click_close_button

      issues_table.find_row_by_resource_name(@adjacent_links_page.title).click_resource_name_link

      expect(link_count).to eq(1)
      expect(merged_link_text).to include(first_link_text)
      expect(merged_link_text).to include(second_link_text)
    end
  end
end
