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

RSpec.describe "SmallTextContrastRule", type: :feature do
  include RuleTestHelper

  context "when testing small text contrast" do
    it "identifies small text with insufficient contrast" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("p")
      end
    end

    it "provides useful data for fixing contrast issues" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'

      issues = find_issues(:small_text_contrast, input_html, "page-123")

      if issues.any?
        data = issues.first[:data]
        expect(data[:id]).to include("page-123")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'

      page_issues = find_issues(:small_text_contrast, input_html, "page-123")
      assignment_issues = find_issues(:small_text_contrast, input_html, "assignment-456")
      file_issues = find_issues(:small_text_contrast, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end

    it "fixes small text contrast issues by updating the text color" do
      input_html = '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>'
      compliant_color = "#000000"
      expected_html = "<p style=\"color: #{compliant_color}; background-color: #FFFFFF;\">Low contrast text</p>"

      fixed_html = fix_issue(:small_text_contrast, input_html, "./*", compliant_color)

      expect(fixed_html).to eq(expected_html)
    end
  end
end
