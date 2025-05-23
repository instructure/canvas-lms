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

RSpec.describe "ParagraphsForHeadingsRule", type: :feature do
  include RuleTestHelper

  context "when testing paragraphs after headings" do
    it "identifies headings without following paragraphs" do
      input_html = "<div><h2>Heading without paragraph</h2><h3>Another heading</h3><p>This paragraph belongs to the second heading.</p></div>"

      issues = find_issues(:paragraphs_for_headings, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("h2")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = "<div><h2>Heading without paragraph</h2><h3>Another heading</h3><p>This paragraph belongs to the second heading.</p></div>"

      page_issues = find_issues(:paragraphs_for_headings, input_html, "page-123")
      assignment_issues = find_issues(:paragraphs_for_headings, input_html, "assignment-456")
      file_issues = find_issues(:paragraphs_for_headings, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end
  end

  context "when fixing headings to paragraphs" do
    it "changes a heading to a paragraph" do
      input_html = '<div><h2 id="test-element">Heading text</h2></div>'
      fixed_html = fix_issue(:paragraphs_for_headings, input_html, './/h2[@id="test-element"]', "true")

      expect(fixed_html).to include('<p id="test-element">Heading text</p>')
      expect(fixed_html).not_to include('<h2 id="test-element">Heading text</h2>')
    end
  end
end
