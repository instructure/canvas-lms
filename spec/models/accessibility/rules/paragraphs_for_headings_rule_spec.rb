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

describe Accessibility::Rules::ParagraphsForHeadingsRule do
  include RuleTestHelper

  context "when testing heading lengths" do
    it "finds a heading with very long text" do
      input_html = "<div><h2>This heading is way much longer than 120 characters. This heading is way much longer than 120 characters. This heading is way much longer than 120 characters.</h2></div>"

      page_issues = find_issues(:paragraphs_for_headings, input_html, "page-123")
      assignment_issues = find_issues(:paragraphs_for_headings, input_html, "assignment-456")
      file_issues = find_issues(:paragraphs_for_headings, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end

    it "skips a heading with short text" do
      input_html = "<div><h2>Short heading</h2></div>"

      page_issues = find_issues(:paragraphs_for_headings, input_html, "page-123")
      assignment_issues = find_issues(:paragraphs_for_headings, input_html, "assignment-456")

      expect(page_issues).to be_empty
      expect(assignment_issues).to be_empty
    end
  end

  context "find a heading with short text" do
    it "changes a heading to a paragraph" do
      input_html = '<div><h2 id="test-element">Heading text</h2></div>'
      fixed_html = fix_issue(:paragraphs_for_headings, input_html, './/h2[@id="test-element"]', "true")

      expect(fixed_html).to include('<p id="test-element">Heading text</p>')
      expect(fixed_html).not_to include('<h2 id="test-element">Heading text</h2>')
    end

    it "change to paragraph button must be in the form" do
      expect(Accessibility::Rules::ParagraphsForHeadingsRule.new.form(nil).label).to eq("Change to paragraph")
    end
  end

  describe ".display_name" do
    it "returns the correct display name" do
      expect(described_class.new.display_name).to eq(I18n.t("Heading is too long"))
    end
  end

  describe ".message" do
    it "returns the correct message" do
      expect(described_class.new.message).to eq(I18n.t("This heading is very long. Is it meant to be a paragraph?"))
    end
  end

  describe ".why" do
    it "returns the correct explanation" do
      expected_messages = [
        I18n.t(
          "Sighted users scan web pages by identifying headings. Similarly, screen reader users rely on headings" \
          "to quickly understand and navigate your content. If a heading is too long, it can be confusing to scan," \
          "harder to read aloud by assistive technology, and less effective for outlining your page."
        ),
        I18n.t("Keep headings short, specific, and meaningful, not full sentences or paragraphs.")
      ]
      expect(described_class.new.why).to eq(expected_messages)
    end
  end
end
