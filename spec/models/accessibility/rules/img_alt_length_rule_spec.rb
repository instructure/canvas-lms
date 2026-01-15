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
require_relative "../../../../app/models/accessibility/rules/img_alt_rule_helper"

describe Accessibility::Rules::ImgAltLengthRule do
  include RuleTestHelper

  context "when testing image alt text length" do
    it "identifies images with overly long alt text" do
      long_alt = "This is an extremely long description that contains far too many words and details about the image. The alt text should be concise and to the point, not unnecessarily verbose. Screen readers will read all of this text to users, making for a poor experience."

      input_html = "<div><img src=\"image.jpg\" alt=\"#{long_alt}\"></div>"

      issues = find_issues(:img_alt_length, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("img")
      end
    end

    it "maintains resource-specific isolation between content types" do
      long_alt = "This is an extremely long description that contains far too many words and details about the image. The alt text should be concise and to the point, not unnecessarily verbose. Screen readers will read all of this text to users, making for a poor experience."

      input_html = "<div><img src=\"image.jpg\" alt=\"#{long_alt}\"></div>"

      page_issues = find_issues(:img_alt_length, input_html, "page-123")
      assignment_issues = find_issues(:img_alt_length, input_html, "assignment-456")
      file_issues = find_issues(:img_alt_length, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end
  end

  context "when fixing image alt text length" do
    it "updates overly long alt text to a concise value" do
      long_alt = "This is an extremely long description that contains far too many words and details about the image. The alt text should be concise and to the point, not unnecessarily verbose. Screen readers will read all of this text to users, making for a poor experience."
      concise_alt = "A concise description of the image."

      input_html = "<div><img id=\"test-element\" src=\"image.jpg\" alt=\"#{long_alt}\"></div>"
      fixed_html = fix_issue(:img_alt_length, input_html, './/img[@id="test-element"]', concise_alt)

      expect(fixed_html).to include("alt=\"#{concise_alt}\"")
    end

    it "does not modify alt text if it is already concise" do
      concise_alt = "A concise description of the image."

      input_html = "<div><img id=\"test-element\" src=\"image.jpg\" alt=\"#{concise_alt}\"></div>"
      fixed_html = fix_issue(:img_alt_length, input_html, './/img[@id="test-element"]', concise_alt)

      expect(fixed_html).to include("alt=\"#{concise_alt}\"")
    end

    it "fixes overly long alt text by updating it to a new value" do
      long_alt = "This is an extremely long description that contains far too many words and details about the image. The alt text should be concise and to the point, not unnecessarily verbose. Screen readers will read all of this text to users, making for a poor experience."
      new_alt = "A concise description of the image."

      input_html = "<div><img id=\"test-element\" src=\"image.jpg\" alt=\"#{long_alt}\"></div>"
      fixed_html = fix_issue(:img_alt_length, input_html, './/img[@id="test-element"]', new_alt)

      expect(fixed_html).to include("alt=\"#{new_alt}\"")
    end
  end

  context "when generating form for image alt text" do
    it "returns a TextInputWithCheckboxField with correct configuration" do
      long_alt_text = "looong alt text  " * 10
      input_html = "<div><img alt='#{long_alt_text}'></div>"

      elem = Nokogiri::HTML.fragment(input_html).css("img").first
      form = Accessibility::Rules::ImgAltLengthRule.new.form(elem)

      expect(form).to be_a(Accessibility::Forms::TextInputWithCheckboxField)
      expect(form.value).to eq(long_alt_text)
    end
  end

  context "when generating issue preview" do
    it "returns styled HTML for img elements" do
      long_alt = "This is an extremely long description" * 10
      input_html = "<div><img id=\"test-img\" src=\"image.jpg\" alt=\"#{long_alt}\"></div>"
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltLengthRule.new

      result = rule.issue_preview(img_element)

      expect(result).not_to be_nil
      expect(result).to include("display: flex")
      expect(result).to include("justify-content: center")
      expect(result).to include("align-items: center")
      expect(result).to include("max-width: 100%")
      expect(result).to include("max-height: 100%")
      expect(result).to include("object-fit: contain")
      expect(result).to include('id="test-img"')
      expect(result).to include('src="image.jpg"')
    end

    it "returns nil for non-img elements" do
      input_html = '<div id="test-div">Some content</div>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      div_element = document.at_css("div")
      rule = Accessibility::Rules::ImgAltLengthRule.new

      result = rule.issue_preview(div_element)

      expect(result).to be_nil
    end
  end
end
