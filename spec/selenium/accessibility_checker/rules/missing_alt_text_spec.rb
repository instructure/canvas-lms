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

describe "Accessibility Checker - Missing Alt Text Rule", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AccessibilityCheckerPage
  include AccessibilityChecker::BatchDataFactory

  before(:once) do
    course_with_teacher(active_all: true)
    enable_accessibility_checker(@course)
  end

  before do
    user_session(@teacher)
  end

  context "Fixing missing alt text issues" do
    let(:alt_text_value) { "A descriptive alt text" }

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
      wizard.alt_text_controls.enter_alt_text(alt_text_value)
      wizard.apply_fix

      expect(wizard.footer.save_and_next_enabled?).to be true
    end

    it "displays success view when save and next button is clicked" do
      wizard = remediation_wizard
      wizard.alt_text_controls.enter_alt_text(alt_text_value)

      wizard.apply_fix
      wizard.save_and_next

      expect(wizard.success_view_exists?).to be true
    end

    it "disables alt text input when image is marked as decorative" do
      wizard = remediation_wizard

      wizard.alt_text_controls.mark_as_decorative

      expect(wizard.alt_text_controls.alt_text_input_disabled?).to be true
    end
  end
end
