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

describe Accessibility::Rules::TableCaptionRule do
  include RuleTestHelper

  context "when testing table captions" do
    it "identifies tables without captions" do
      input_html = "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      issues = find_issues(:table_caption, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("table")
      end
    end

    it "calls the correct method on caption" do
      elem = double("Element", tag_name: "table")
      caption = double("Caption", text: "Valid Caption")
      allow(elem).to receive(:query_selector).with("caption").and_return(caption)

      expect(caption).to receive(:text).and_return("Valid Caption")
      expect(caption).not_to receive(:text_content)

      Accessibility::Rules::TableCaptionRule.new.test(elem)
    end

    it "maintains resource-specific isolation between content types" do
      input_html = "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      page_issues = find_issues(:table_caption, input_html, "page-123")
      assignment_issues = find_issues(:table_caption, input_html, "assignment-456")
      file_issues = find_issues(:table_caption, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end
  end

  context "when fixing table captions" do
    it "adds a caption to a table without one" do
      input_html = "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"
      expected_html = "<table><caption>Table description</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      fixed_html = fix_issue(:table_caption, input_html, "./*", "Table description")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "updates the caption of a table with an existing caption" do
      input_html = "<table><caption>Table description</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"
      expected_html = "<table><caption>Updated description</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      updated_html = fix_issue(:table_caption, input_html, "./*", "Updated description")

      expect(updated_html.delete("\n")).to eq(expected_html)
    end

    it "updates an empty caption with content and returns the table for preview" do
      doc = Nokogiri::HTML::DocumentFragment.parse('<table border="1"><caption></caption><tbody><tr><th>Day</th><th>Mushroom</th></tr><tr><td>Monday</td><td>Morel</td></tr></tbody></table>')
      table_element = doc.at_css("table")
      rule = Accessibility::Rules::TableCaptionRule.new

      result = rule.fix!(table_element, "Weekly Mushroom Schedule")

      expect(result).not_to be_nil
      expect(result).to be_a(Hash)
      expect(result[:changed]).to eq(table_element)
      expect(table_element.at_css("caption").content).to eq("Weekly Mushroom Schedule")
    end
  end

  context "form" do
    it "returns the proper form" do
      expect(Accessibility::Rules::TableCaptionRule.new.form(nil).label).to eq("Table caption")
    end
  end
end
