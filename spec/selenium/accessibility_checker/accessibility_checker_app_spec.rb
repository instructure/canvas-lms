# frozen_string_literal: true

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

require_relative "../common"
require_relative "page_objects/accessibility_pages"
require_relative "page_objects/accessibility_dashboard"
require_relative "page_objects/accessibility_drawer"

describe "Accessibility Checker App UI", type: :selenium do
  include_context "in-process server selenium tests"
  include AccessibilityPages
  include AccessibilityDrawer
  include AccessibilityDashboard

  context "As a teacher" do
    before do
      course_with_teacher_logged_in
      @course.enable_feature!(:accessibility_tab_enable)
    end

    context "renders" do
      it "the Accessibility Checker App UI" do
        visit_accessibility_home_page(@course.id)
        expect(accessibility_checker_container).to be_displayed
      end
    end

    context "fixes accessibility issues on a page" do
      skip "LMA-208" do
        context "form type: button-only" do
          it "page violates the paragraphs for headings rule" do
            page = @course.wiki_pages.create!(title: "Page1", body: paragraphs_for_headings_html)
            visit_accessibility_home_page(@course.id)
            expect(accessibility_checker_container).to be_displayed
            fix_button(1).click
            apply_button.click
            expect(issue_preview).to contain_css("p")
            undo_button.click
            expect(issue_preview).to contain_css("h2")
            apply_button.click
            expect(issue_preview).to contain_css("p")
            save_button.click
            expect(page.reload.body).to eq paragraphs_for_headings_html.gsub("h2", "p")
          end
        end

        context "form type: radio button" do
          it "page violates the headings start at h2 rule" do
            page = @course.wiki_pages.create!(title: "Page1", body: headings_start_at_h2_html)
            visit_accessibility_home_page(@course.id)
            expect(accessibility_checker_container).to be_displayed
            fix_button(1).click
            apply_button.click
            expect(issue_preview).to contain_css("h2")
            undo_button.click
            expect(issue_preview).to contain_css("h1")
            radio_button_form_remove_heading.click
            apply_button.click
            expect(issue_preview).to contain_css("p")
            save_button.click
            expect(page.reload.body).to eq headings_start_at_h2_html.gsub("h1", "p")
          end
        end

        context "form type: text input with checkbox" do
          context "page violates img alt rule" do
            it "selects the checkbox to fix the issue" do
              role = 'role="presentation"'
              page = @course.wiki_pages.create!(title: "Page1", body: img_alt_rule_html)
              visit_accessibility_home_page(@course.id)
              expect(accessibility_checker_container).to be_displayed
              fix_button(1).click
              text_input_with_checkbox_form_checkbox.click
              save_button.click
              expect(page.reload.body).to include role
            end

            it "selects the text input to fix the issue" do
              alt_text = 'alt="this is an alt"'
              page = @course.wiki_pages.create!(title: "Page1", body: img_alt_rule_html)
              visit_accessibility_home_page(@course.id)
              expect(accessibility_checker_container).to be_displayed
              fix_button(1).click
              text_input_with_checkbox_form_input.send_keys(alt_text.gsub("alt=", "").delete('"'))
              save_button.click
              expect(page.reload.body).to include alt_text
            end
          end
        end

        context "form type: text input" do
          it "page violates the table caption rule" do
            caption = "<caption>This is a caption</caption>"
            page = @course.wiki_pages.create!(title: "Page1", body: table_caption_rule_html)
            visit_accessibility_home_page(@course.id)
            expect(accessibility_checker_container).to be_displayed
            fix_button(1).click
            text_input_form_input.send_keys("This is a caption")
            apply_button.click
            expect(issue_preview).to contain_css("caption")
            undo_button.click
            expect(issue_preview).not_to contain_css("caption")
            apply_button.click
            expect(issue_preview).to contain_css("caption")
            save_button.click
            expect(page.reload.body).to include caption
          end
        end

        context "form type: color picker" do
          it "page violates the small text contrast rule" do
            base_color = { rgba: "rgba(248, 202, 198, 1)" }
            new_color = { hex: "248029", rgba: "rgba(36, 128, 41, 1)" }
            page = @course.wiki_pages.create!(title: "Page1", body: small_text_contrast_rule_html)
            visit_accessibility_home_page(@course.id)
            expect(accessibility_checker_container).to be_displayed
            fix_button(1).click
            color_picker_form_input.send_keys(:control, "a")
            color_picker_form_input.send_keys(new_color[:hex])
            apply_button.click
            expect(issue_preview("> p > span").css_value("color")).to eq(new_color[:rgba])
            undo_button.click
            expect(issue_preview("> p > span").css_value("color")).to eq(base_color[:rgba])
            apply_button.click
            expect(issue_preview("> p > span").css_value("color")).to eq(new_color[:rgba])
            save_button.click
            expect(page.reload.body).to include "color: ##{new_color[:hex]}"
          end
        end
      end
    end
  end
end
