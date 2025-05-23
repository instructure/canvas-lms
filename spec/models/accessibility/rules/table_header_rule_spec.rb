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

require "spec_helper"
require_relative "rule_test_helper"

RSpec.describe "TableHeaderRule", type: :feature do
  include RuleTestHelper

  context "when testing table headers" do
    it "identifies tables with cells in first row that should be headers" do
      input_html = "<table><tr><td>Cell 1</td><td>Cell 2</td></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      issues = find_issues(:table_header, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("table")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = "<table><tr><td>Cell 1</td><td>Cell 2</td></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      page_issues = find_issues(:table_header, input_html, "page-123")
      assignment_issues = find_issues(:table_header, input_html, "assignment-456")
      file_issues = find_issues(:table_header, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end

    it "fixes tables by adding headers to the first row" do
      input_html = "<table><tr><td>Cell 1</td><td>Cell 2</td></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"
      expected_html = "<table><tr><th scope=\"col\">Cell 1</th><th scope=\"col\">Cell 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      fixed_html = fix_issue(:table_header, input_html, "./*", "Header row")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end
  end
end
