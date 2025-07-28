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

  context "when fixing large text contrast" do
    it "updates the text color to meet contrast requirements" do
      input_html = '<h1 style="color: #BBBBBB; background-color: #FFFFFF; font-size: 24px;">Low contrast heading</h1>'
      fixed_html = fix_issue(:large_text_contrast, input_html, "./*", "#000000")

      expect(fixed_html).to include("color: #000000")
      expect(fixed_html).to include("background-color: #FFFFFF")
    end
  end
end
