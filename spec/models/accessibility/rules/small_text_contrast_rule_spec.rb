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

require_relative "rule_test_helper"

describe Accessibility::Rules::SmallTextContrastRule do
  include RuleTestHelper

  context "when testing small text contrast" do
    it "identifies small text with insufficient contrast" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("p")
      end
    end

    it "provides useful data for fixing contrast issues" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      if issues.any?
        data = issues.first[:data]
        expect(data[:id]).to include("page-123")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'

      page_issues = find_issues(:small_text_contrast, input_html, "page-123")
      assignment_issues = find_issues(:small_text_contrast, input_html, "assignment-456")
      file_issues = find_issues(:small_text_contrast, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end

    it "fixes small text contrast issues by updating the text color" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'
      compliant_color = "#000000"
      expected_html = "<p style=\"color: #{compliant_color}; background-color: #FFFFFF;\">Low contrast text</p>"

      fixed_html = fix_issue(:small_text_contrast, input_html, "./*", compliant_color)

      expect(fixed_html).to eq(expected_html)
    end
  end

  context "when testing with background shorthand property" do
    it "detects contrast issues with background shorthand containing hex color" do
      input_html = '<p style="color: #CCCCCC; background: #FFFFFF;">Low contrast text</p>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
    end

    it "skips elements with background-image property" do
      input_html = '<p style="color: #FFFFFF; background-image: url(test.jpg); font-size: 12px;">White text</p>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).to be_empty
    end

    it "skips elements with background containing url()" do
      input_html = '<p style="color: #FFFFFF; background: url(test.jpg) no-repeat; font-size: 12px;">White text</p>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).to be_empty
    end

    it "skips elements with background containing gradient" do
      input_html = '<p style="color: #FFFFFF; background: linear-gradient(red, blue); font-size: 12px;">White text</p>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).to be_empty
    end
  end

  context "when testing with pt font-size units" do
    it "detects small text with pt units (12pt = 16px)" do
      input_html = '<span style="color: #CCCCCC; background-color: #FFFFFF; font-size: 12pt;">Low contrast text</span>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
    end

    it "detects small text at small threshold (13pt = ~17.3px)" do
      input_html = '<span style="color: #CCCCCC; background-color: #FFFFFF; font-size: 13pt;">Low contrast text</span>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
    end

    it "does not detect text at or above large text threshold (14pt = ~18.6px)" do
      input_html = '<span style="color: #CCCCCC; background-color: #FFFFFF; font-size: 14pt;">Low contrast text</span>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).to be_empty
    end
  end

  context "when fixing small text contrast" do
    it "updates the text color to meet contrast requirements" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'
      fixed_html = fix_issue(:small_text_contrast, input_html, "./*", "#000000")

      expect(fixed_html).to include("color: #000000")
      expect(fixed_html).to include("background-color: #FFFFFF")
    end

    it "works with background shorthand" do
      input_html = '<p style="color: #CCCCCC; background: #FFFFFF;">Low contrast text</p>'
      fixed_html = fix_issue(:small_text_contrast, input_html, "./*", "#000000")

      expect(fixed_html).to include("color: #000000")
    end
  end

  context "when generating form data" do
    let(:rule) { Accessibility::Rules::SmallTextContrastRule.new }

    it "suggests black text when it meets contrast threshold with background" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      element = document.at_xpath("./*")

      form_field = rule.form(element)
      form_hash = form_field.to_h

      expect(form_hash[:value]).to eq("#000000")
      expect(form_hash[:background_color]).to eq("#FFFFFF")
      expect(form_hash[:options]).to eq(["normal"])
    end

    it "suggests white text when black text does not meet contrast threshold with background" do
      input_html = '<p style="color: #CCCCCC; background-color: #000000;">Low contrast text</p>'
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      element = document.at_xpath("./*")

      form_field = rule.form(element)
      form_hash = form_field.to_h

      expect(form_hash[:value]).to eq("#FFFFFF")
      expect(form_hash[:background_color]).to eq("#000000")
      expect(form_hash[:options]).to eq(["normal"])
    end

    it "suggests black text for light backgrounds (gray)" do
      input_html = '<p style="color: #CCCCCC; background-color: #EEEEEE;">Low contrast text</p>'
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      element = document.at_xpath("./*")

      form_field = rule.form(element)
      form_hash = form_field.to_h

      expect(form_hash[:value]).to eq("#000000")
      expect(form_hash[:background_color]).to eq("#EEEEEE")
    end

    it "suggests white text for dark backgrounds (dark gray)" do
      input_html = '<p style="color: #CCCCCC; background-color: #333333;">Low contrast text</p>'
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      element = document.at_xpath("./*")

      form_field = rule.form(element)
      form_hash = form_field.to_h

      expect(form_hash[:value]).to eq("#FFFFFF")
      expect(form_hash[:background_color]).to eq("#333333")
    end
  end
end
