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

RSpec.describe "HeadingsSequenceRule", type: :feature do
  include RuleTestHelper

  context "when testing headings sequence" do
    it "identifies a heading that skips a level" do
      input_html = "<div><h2>First heading</h2><h4>Skipped heading level</h4></div>"

      issues = find_issues(:headings_sequence, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("h4")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = "<div><h2>First heading</h2><h4>Skipped heading level</h4></div>"

      page_issues = find_issues(:headings_sequence, input_html, "page-123")
      assignment_issues = find_issues(:headings_sequence, input_html, "assignment-456")
      file_issues = find_issues(:headings_sequence, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end
  end

  context "when fixing heading sequences" do
    it "fixes a skipped heading level" do
      input_html = '<div id="test-element"><h2>First heading</h2><h4 id="test-element">Skipped heading level</h4></div>'
      fixed_html = fix_issue(:headings_sequence, input_html, ".//h4[@id='test-element']", "Fix heading hierarchy")

      expect(fixed_html).to include('<h3 id="test-element">Skipped heading level</h3>')
      expect(fixed_html).not_to include('<h4 id="test-element">Skipped heading level</h4>')
    end

    it "removes heading style" do
      input_html = '<div id="test-element"><h2>First heading</h2><h4 id="test-element">Skipped heading level</h4></div>'
      fixed_html = fix_issue(:headings_sequence, input_html, ".//h4[@id='test-element']", "Remove heading style")

      expect(fixed_html).to include('<p id="test-element">Skipped heading level</p>')
      expect(fixed_html).not_to include('<h4 id="test-element">Skipped heading level</h4>')
    end
  end
end
