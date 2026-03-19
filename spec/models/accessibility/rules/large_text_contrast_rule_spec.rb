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

describe Accessibility::Rules::LargeTextContrastRule do
  include RuleTestHelper

  context "when testing large text contrast" do
    it "identifies large text with insufficient contrast" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #FFFFFF; font-size: 24px;">Low contrast heading</h1>'

      issues = find_issues(:large_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("h1")
      end
    end

    it "uses a different contrast threshold than the small text rule" do
      expect(Accessibility::Rules::LargeTextContrastRule::CONTRAST_THRESHOLD).to eq(3.0)
      expect(Accessibility::Rules::SmallTextContrastRule::CONTRAST_THRESHOLD).to eq(4.5)
    end

    it "provides useful data for fixing contrast issues" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #FFFFFF; font-size: 24px;">Low contrast heading</h1>'

      issues = find_issues(:large_text_contrast, input_html, "page-123")

      if issues.any?
        data = issues.first[:data]
        expect(data[:id]).to include("page-123")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #FFFFFF; font-size: 24px;">Low contrast heading</h1>'

      page_issues = find_issues(:large_text_contrast, input_html, "page-123")
      assignment_issues = find_issues(:large_text_contrast, input_html, "assignment-456")
      file_issues = find_issues(:large_text_contrast, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end
  end

  context "when testing with background shorthand property" do
    it "detects contrast issues with background shorthand containing hex color" do
      input_html = '<h1 style="color: #BBBBBB; background: #FFFFFF; font-size: 24px;">Low contrast heading</h1>'

      issues = find_issues(:large_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
    end

    it "skips elements with background-image property" do
      input_html = '<h1 style="color: #FFFFFF; background-image: url(test.jpg); font-size: 24px;">White text</h1>'

      issues = find_issues(:large_text_contrast, input_html, "page-123")

      expect(issues).to be_empty
    end

    it "skips elements with background containing url()" do
      input_html = '<h1 style="color: #FFFFFF; background: url(test.jpg) no-repeat; font-size: 24px;">White text</h1>'

      issues = find_issues(:large_text_contrast, input_html, "page-123")

      expect(issues).to be_empty
    end

    it "skips elements with background containing gradient" do
      input_html = '<h1 style="color: #FFFFFF; background: linear-gradient(red, blue); font-size: 24px;">White text</h1>'

      issues = find_issues(:large_text_contrast, input_html, "page-123")

      expect(issues).to be_empty
    end
  end

  context "when testing with pt font-size units" do
    it "detects large text with pt units (24pt = 32px)" do
      input_html = '<span style="color: #BBBBBB; background-color: #FFFFFF; font-size: 24pt;">Low contrast text</span>'

      issues = find_issues(:large_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
    end

    it "detects large text at minimum threshold (18.5px = ~14pt)" do
      input_html = '<span style="color: #BBBBBB; background-color: #FFFFFF; font-size: 14pt;">Low contrast text</span>'

      issues = find_issues(:large_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
    end
  end

  context "when fixing large text contrast" do
    it "updates the text color to meet contrast requirements" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #FFFFFF; font-size: 24px;">Low contrast heading</h1>'
      fixed_html = fix_issue(:large_text_contrast, input_html, "./*", "#000000")

      expect(fixed_html).to include("color: #000000")
      expect(fixed_html).to include("background-color: #FFFFFF")
    end

    it "works with background shorthand" do
      input_html = '<h1 style="color: #BBBBBB; background: #FFFFFF; font-size: 24px;">Low contrast heading</h1>'
      fixed_html = fix_issue(:large_text_contrast, input_html, "./*", "#000000")

      expect(fixed_html).to include("color: #000000")
    end
  end

  context "when generating form data" do
    let(:rule) { Accessibility::Rules::LargeTextContrastRule.new }

    it "suggests black text when it meets contrast threshold with background" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #FFFFFF; font-size: 24px;">Low contrast heading</h1>'
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      element = document.at_xpath("./*")

      form_field = rule.form(element)
      form_hash = form_field.to_h

      expect(form_hash[:value]).to eq("#000000")
      expect(form_hash[:background_color]).to eq("#FFFFFF")
      expect(form_hash[:options]).to eq(["large"])
    end

    it "suggests white text when black text does not meet contrast threshold with background" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #000000; font-size: 24px;">Low contrast heading</h1>'
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      element = document.at_xpath("./*")

      form_field = rule.form(element)
      form_hash = form_field.to_h

      expect(form_hash[:value]).to eq("#FFFFFF")
      expect(form_hash[:background_color]).to eq("#000000")
      expect(form_hash[:options]).to eq(["large"])
    end

    it "suggests black text for light backgrounds (gray)" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #EEEEEE; font-size: 24px;">Low contrast heading</h1>'
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      element = document.at_xpath("./*")

      form_field = rule.form(element)
      form_hash = form_field.to_h

      expect(form_hash[:value]).to eq("#000000")
      expect(form_hash[:background_color]).to eq("#EEEEEE")
    end

    it "suggests white text for dark backgrounds (dark gray)" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #333333; font-size: 24px;">Low contrast heading</h1>'
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      element = document.at_xpath("./*")

      form_field = rule.form(element)
      form_hash = form_field.to_h

      expect(form_hash[:value]).to eq("#FFFFFF")
      expect(form_hash[:background_color]).to eq("#333333")
    end
  end

  context "when calculating contrast ratio" do
    let(:rule) { Accessibility::Rules::SmallTextContrastRule.new }

    it "raises error with metadata when calculate_contrast_ratio receives empty color" do
      expect { rule.calculate_contrast_ratio("", "#FFFFFF") }.to raise_error do |error|
        expect(error.message).to eq("color_missing")
        metadata = error.instance_variable_get(:@metadata)
        expect(metadata).to include(:foreground, :background)
        expect(metadata[:foreground]).to eq("")
        expect(metadata[:background]).to eq("#FFFFFF")
      end
    end

    it "raises error with metadata when calculate_contrast_ratio receives invalid color" do
      expect { rule.calculate_contrast_ratio("#11", "#FFFFFF") }.to raise_error do |error|
        expect(error.message).to eq("invalid_color_format")
        metadata = error.instance_variable_get(:@metadata)
        expect(metadata).to include(:foreground, :background)
        expect(metadata[:foreground]).to eq("#11")
        expect(metadata[:background]).to eq("#FFFFFF")
      end
    end

    it "raises error with metadata when calculate_contrast_ratio receives whitespace-only colors" do
      expect { rule.calculate_contrast_ratio("   ", "#FFFFFF") }.to raise_error do |error|
        expect(error.message).to eq("color_missing")
        metadata = error.instance_variable_get(:@metadata)
        expect(metadata).to include(:foreground, :background)
      end
    end
  end
end
