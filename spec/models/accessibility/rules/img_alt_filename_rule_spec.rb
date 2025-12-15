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

describe Accessibility::Rules::ImgAltFilenameRule do
  include RuleTestHelper

  context "when testing image alt text using filenames" do
    it "identifies images using filenames as alt text if alt text contains filename from the src" do
      input_html = '<div><img src="image.jpg" alt="image.jpg"></div>'

      issues = find_issues(:img_alt_filename, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("img")
      end
    end

    it "identifies images using filenames as alt text if alt text contains an arbitrary filename" do
      input_html = '<div><img src="image.jpg" alt="picture.png"></div>'

      issues = find_issues(:img_alt_filename, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("img")
      end
    end

    it "identifies images using filenames as alt text if alt text contains an arbitrary filename with path" do
      input_html = '<div><img src="image.jpg" alt="/path/picture.png"></div>'

      issues = find_issues(:img_alt_filename, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("img")
      end
    end

    it "do not signal an issue if the alt text does not seem to contain a filename extension separated by a dot" do
      input_html = '<div><img src="image.jpg" alt="/path/picture"></div>'

      issues = find_issues(:img_alt_filename, input_html, "page-123")

      expect(issues).to be_empty
    end

    it "do not signal an issue if the alt text has spaces in it" do
      input_html = '<div><img src="image.jpg" alt="picture of the index.html"></div>'

      issues = find_issues(:img_alt_filename, input_html, "page-123")

      expect(issues).to be_empty
    end
  end

  context "when fixing image alt text using filenames" do
    it "updates the alt text to a descriptive value" do
      input_html = '<div><img id="test-element" src="image.jpg" alt="image.jpg"></div>'
      fixed_html = fix_issue(:img_alt_filename, input_html, './/img[@id="test-element"]', "Descriptive alt text")

      expect(fixed_html).to eq('<div><img id="test-element" src="image.jpg" alt="Descriptive alt text"></div>')
    end
  end

  context "when generating form for image alt text" do
    it "returns a TextInputWithCheckboxField with correct configuration" do
      input_html = '<div><img src="image.jpg" alt="image"></div>'
      elem = Nokogiri::HTML.fragment(input_html).css("img").first
      form = Accessibility::Rules::ImgAltFilenameRule.new.form(elem)

      expect(form).to be_a(Accessibility::Forms::TextInputWithCheckboxField)
      expect(form.value).to eq("image")
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
      input_html = '<div><img id="test-img" src="image.jpg" alt="image.jpg"></div>'
      document = Nokogiri::HTML.fragment(input_html)
      extend_nokogiri_with_dom_adapter(document)
      img_element = document.at_css("img")
      rule = Accessibility::Rules::ImgAltFilenameRule.new

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
      rule = Accessibility::Rules::ImgAltFilenameRule.new

      result = rule.issue_preview(div_element)

      expect(result).to be_nil
    end
  end
end
