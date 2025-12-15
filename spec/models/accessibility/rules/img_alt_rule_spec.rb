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

describe Accessibility::Rules::ImgAltRule do
  include RuleTestHelper

  context "when testing image alt text" do
    it "identifies images without alt text" do
      input_html = '<div><img src="image.jpg"></div>'

      issues = find_issues(:img_alt, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("img")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = '<div><img src="image.jpg"></div>'

      page_issues = find_issues(:img_alt, input_html, "page-123")
      assignment_issues = find_issues(:img_alt, input_html, "assignment-456")
      file_issues = find_issues(:img_alt, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end
  end

  context "when fixing image alt text" do
    it "updates the alt text of an image" do
      input_html = '<div><img id="test-element" src="image.jpg" alt=""></div>'
      fixed_html = fix_issue(:img_alt, input_html, './/img[@id="test-element"]', "Descriptive alt text")

      expect(fixed_html).to include('<img id="test-element" src="image.jpg" alt="Descriptive alt text">')
    end

    it "marks image as decorative when value is nil" do
      input_html = '<div><img id="test-element" src="image.jpg"></div>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltRule.new

      result = rule.fix!(img_element, nil)

      expect(result).to be_a(Array)
      expect(result.length).to eq(2)
      expect(img_element["role"]).to eq("presentation")
      expect(img_element["alt"]).to eq("")
    end

    it "returns styled HTML as second element in array" do
      input_html = '<div><img id="test-element" src="image.jpg" alt=""></div>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltRule.new

      result = rule.fix!(img_element, "Descriptive alt text")

      expect(result).to be_a(Array)
      expect(result.length).to eq(2)
      expect(result[1]).to include("display: flex")
      expect(result[1]).to include("justify-content: center")
      expect(result[1]).to include("align-items: center")
      expect(result[1]).to include("max-width: 100%")
      expect(result[1]).to include("max-height: 100%")
      expect(result[1]).to include("object-fit: contain")
      expect(result[1]).to include('alt="Descriptive alt text"')
    end

    it "raises an error when alt text is a generic filename" do
      input_html = '<div><img id="test-element" src="https://example.com/beach-photo.jpg" alt=""></div>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltRule.new

      expect do
        rule.fix!(img_element, "beach-photo.jpg")
      end.to raise_error(StandardError, /Alt text can not be a filename/)
    end

    it "allows alt text without extension" do
      input_html = '<div><img id="test-element" src="https://example.com/sunset.png" alt=""></div>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltRule.new

      expect do
        rule.fix!(img_element, "sunset")
      end.not_to raise_error
    end

    it "allows alt text that is different from the filename" do
      input_html = '<div><img id="test-element" src="https://example.com/img123.jpg" alt=""></div>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltRule.new

      expect do
        rule.fix!(img_element, "A beautiful sunset over the ocean")
      end.not_to raise_error
    end
  end

  context "when generating form for image alt text" do
    it "returns a TextInputWithCheckboxField with correct configuration" do
      input_html = '<div><img src="image.jpg"></div>'
      elem = Nokogiri::HTML.fragment(input_html).css("img").first
      form = Accessibility::Rules::ImgAltRule.new.form(elem)

      expect(form).to be_a(Accessibility::Forms::TextInputWithCheckboxField)
      expect(form.value).to eq("")
    end
  end

  context "when generating alt text automatically" do
    it "calls ImgAltRuleHelper and returns generated text" do
      # Create HTML with an image that has a source
      input_html = '<figure><img src="https://example.com/image.jpg" class="hero-image" width="500" height="300"><figcaption>Beautiful scenery</figcaption></figure>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document) # Using method from RuleTestHelper
      img_element = document.at_css("img")

      # Mock ImgAltRuleHelper to verify the call but still use a controlled return value
      helper_class = Accessibility::Rules::ImgAltRuleHelper
      generated_alt = "A beautiful landscape with mountains"
      expect(helper_class).to receive(:generate_alt_text)
        .with("https://example.com/image.jpg")
        .and_return(generated_alt)

      # Call the method with our image element
      result = Accessibility::Rules::ImgAltRule.new.generate_fix(img_element)

      # Verify the result is what our mock returned
      expect(result).to eq(generated_alt)
    end
  end

  context "when generating issue preview" do
    it "returns styled HTML for img elements" do
      input_html = '<div><img id="test-img" src="image.jpg" alt=""></div>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltRule.new

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
      rule = Accessibility::Rules::ImgAltRule.new

      result = rule.issue_preview(div_element)

      expect(result).to be_nil
    end

    it "preserves all image attributes in preview" do
      input_html = '<img id="test-img" src="image.jpg" alt="old alt" class="hero-image" data-id="123">'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltRule.new

      result = rule.issue_preview(img_element)

      expect(result).to include('id="test-img"')
      expect(result).to include('src="image.jpg"')
      expect(result).to include('alt="old alt"')
      expect(result).to include('class="hero-image"')
      expect(result).to include('data-id="123"')
    end
  end
end
