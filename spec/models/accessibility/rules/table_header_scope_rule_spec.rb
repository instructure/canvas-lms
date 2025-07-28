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

describe Accessibility::Rules::TableHeaderScopeRule do
  include RuleTestHelper

  context "when testing table header scope attributes" do
    it "identifies table headers missing scope attributes" do
      input_html = "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      issues = find_issues(:table_header_scope, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("th")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      page_issues = find_issues(:table_header_scope, input_html, "page-123")
      assignment_issues = find_issues(:table_header_scope, input_html, "assignment-456")
      file_issues = find_issues(:table_header_scope, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end

    it "fixes table headers by adding the row scope" do
      input_html = "<table><tr><th id=\"test-element\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"
      expected_html = "<table><tr><th id=\"test-element\" scope=\"row\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"

      fixed_html = fix_issue(:table_header_scope, input_html, './/th[@id="test-element"]', "Row")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "fixes table headers by adding the column scope" do
      input_html = "<table><tr><th id=\"test-element\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"
      expected_html = "<table><tr><th id=\"test-element\" scope=\"column\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"

      fixed_html = fix_issue(:table_header_scope, input_html, './/th[@id="test-element"]', "Column")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "fixes table headers by adding the row group scope" do
      input_html = "<table><tr><th id=\"test-element\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"
      expected_html = "<table><tr><th id=\"test-element\" scope=\"rowgroup\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"

      fixed_html = fix_issue(:table_header_scope, input_html, './/th[@id="test-element"]', "Row group")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "fixes table headers by adding the column group scope" do
      input_html = "<table><tr><th id=\"test-element\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"
      expected_html = "<table><tr><th id=\"test-element\" scope=\"colgroup\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"

      fixed_html = fix_issue(:table_header_scope, input_html, './/th[@id="test-element"]', "Column group")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end
  end
end
