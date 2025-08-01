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

describe "Accessibility Checker App UI", skip: "temporarily skipping due to flakiness", type: :selenium do
  include_context "in-process server selenium tests"
  include AccessibilityPages
  include AccessibilityDrawer
  include AccessibilityDashboard

  context "As a teacher" do
    let(:wiki_page) do
      wiki_page_model(context: @course, body: paragraphs_for_headings_html)
    end

    let(:scan_with_issues) do
      accessibility_resource_scan_model(
        course: @course,
        context: wiki_page,
        workflow_state: "completed",
        resource_updated_at: "2025-07-19T02:18:00Z",
        resource_name: "Tutorial",
        resource_workflow_state: "published",
        issue_count: 1
      )
    end

    before do
      # disable auto-scan on Account
      allow_any_instance_of(Account).to receive(:enqueue_a11y_scan_if_enabled)
      # disable auto-scan on WikiPage
      allow_any_instance_of(WikiPage).to receive(:trigger_accessibility_scan_on_create)
      allow_any_instance_of(WikiPage).to receive(:trigger_accessibility_scan_on_update)
      allow_any_instance_of(WikiPage).to receive(:remove_accessibility_scan)

      course_with_teacher_logged_in
      account = @course.root_account
      account.settings[:enable_content_a11y_checker] = true
      account.save!
    end

    context "renders" do
      it "the Accessibility Checker App UI" do
        visit_accessibility_home_page(@course.id)
        expect_a11y_container_to_be_displayed
      end
    end

    context "fixes accessibility issues on a page" do
      context "form type: button-only" do
        before do
          accessibility_issue_model(
            course: @course,
            accessibility_resource_scan: scan_with_issues,
            rule_type: Accessibility::Rules::ParagraphsForHeadingsRule.id,
            node_path: "./h2",
            metadata: {
              element: "h2",
              form: {
                type: "button",
              },
            }
          )
        end

        it "page violates the paragraphs for headings rule" do
          visit_accessibility_home_page(@course.id)
          expect_a11y_container_to_be_displayed
          fix_button(1).click
          apply_button.click
          expect(issue_preview).to contain_css("p")
          undo_button.click
          expect(issue_preview).to contain_css("h2")
          apply_button.click
          expect(issue_preview).to contain_css("p")
          save_button.click
          expect(wiki_page.reload.body).to eq paragraphs_for_headings_html.gsub("h2", "p")
        end
      end

      context "form type: radio button" do
        before do
          wiki_page.update(body: headings_start_at_h2_html)
          accessibility_issue_model(
            course: @course,
            accessibility_resource_scan: scan_with_issues,
            rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            node_path: "./h1",
            metadata: {
              element: "h1",
              form: {
                label: "How would you like to proceed?",
                type: "radio_input_group",
                value: "Change it to Heading 2",
                undo_text: "Heading structure changed",
                options: ["Change it to Heading 2", "Turn into paragraph"]
              },
            }
          )
        end

        it "page violates the headings start at h2 rule" do
          visit_accessibility_home_page(@course.id)
          expect_a11y_container_to_be_displayed
          fix_button(1).click
          apply_button.click
          expect(issue_preview).to contain_css("h2")
          undo_button.click
          expect(issue_preview).to contain_css("h1")
          radio_button_form_remove_heading.click
          apply_button.click
          expect(issue_preview).to contain_css("p")
          save_button.click
          expect(wiki_page.reload.body).to eq headings_start_at_h2_html.gsub("h1", "p")
        end
      end

      context "form type: text input with checkbox" do
        context "page violates img alt rule" do
          before do
            wiki_page.update(body: img_alt_rule_html)
            accessibility_issue_model(
              course: @course,
              accessibility_resource_scan: scan_with_issues,
              rule_type: Accessibility::Rules::ImgAltRule.id,
              node_path: "./p/img",
              metadata: {
                element: "img",
                form: {
                  type: "checkbox_text_input",
                  checkbox_label: "This image is decorative",
                  label: "Alt text",
                },
              }
            )
          end

          it "selects the checkbox to fix the issue" do
            role = 'role="presentation"'
            visit_accessibility_home_page(@course.id)
            expect_a11y_container_to_be_displayed
            fix_button(1).click
            text_input_with_checkbox_form_checkbox.click
            save_button.click
            expect(wiki_page.reload.body).to include role
          end

          it "selects the text input to fix the issue" do
            alt_text = 'alt="this is an alt"'
            visit_accessibility_home_page(@course.id)
            expect_a11y_container_to_be_displayed
            fix_button(1).click
            text_input_with_checkbox_form_input.send_keys(alt_text.gsub("alt=", "").delete('"'))
            save_button.click
            expect(wiki_page.reload.body).to include alt_text
          end
        end
      end

      context "form type: text input" do
        before do
          wiki_page.update(body: table_caption_rule_html)
          accessibility_issue_model(
            course: @course,
            accessibility_resource_scan: scan_with_issues,
            rule_type: Accessibility::Rules::TableCaptionRule.id,
            node_path: "./table",
            metadata: {
              element: "table",
              form: {
                type: "textinput",
                label: "Table caption"
              },
            }
          )
        end

        it "page violates the table caption rule" do
          caption = "<caption>This is a caption</caption>"
          visit_accessibility_home_page(@course.id)
          expect_a11y_container_to_be_displayed
          fix_button(1).click
          text_input_form_input.send_keys("This is a caption")
          apply_button.click
          expect(issue_preview).to contain_css("caption")
          undo_button.click
          expect(issue_preview).not_to contain_css("caption")
          apply_button.click
          expect(issue_preview).to contain_css("caption")
          save_button.click
          expect(wiki_page.reload.body).to include caption
        end
      end

      context "form type: color picker" do
        before do
          wiki_page.update(body: small_text_contrast_rule_html)
          accessibility_issue_model(
            course: @course,
            accessibility_resource_scan: scan_with_issues,
            rule_type: Accessibility::Rules::SmallTextContrastRule.id,
            node_path: "./p/span",
            metadata: {
              element: "h1",
              form: {
                type: "colorpicker"
              },
            }
          )
        end

        it "page violates the small text contrast rule" do
          base_color = { rgba: "rgba(248, 202, 198, 1)" }
          new_color = { hex: "248029", rgba: "rgba(36, 128, 41, 1)" }
          visit_accessibility_home_page(@course.id)
          expect_a11y_container_to_be_displayed
          fix_button(1).click
          color_picker_form_input.send_keys(:control, "a")
          color_picker_form_input.send_keys(new_color[:hex])
          apply_button.click

          expect(issue_preview(" span").css_value("color")).to eq(new_color[:rgba])
          undo_button.click
          expect(issue_preview(" span").css_value("color")).to eq(base_color[:rgba])
          apply_button.click
          expect(issue_preview(" span").css_value("color")).to eq(new_color[:rgba])
          save_button.click
          expect(wiki_page.reload.body).to include "color: ##{new_color[:hex]}"
        end
      end
    end
  end

  private

  def expect_a11y_container_to_be_displayed
    keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
      expect(accessibility_checker_container).to be_displayed
    end
  end
end
