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

RSpec.describe "ImgAltFilenameRule", type: :feature do
  include RuleTestHelper

  context "when testing image alt text using filenames" do
    it "identifies images using filenames as alt text" do
      input_html = '<div><img src="image.jpg" alt="image.jpg"></div>'

      issues = find_issues(:img_alt_filename, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("img")
      end
    end

    it "maintains resource-specific isolation between content types" do
      input_html = '<div><img src="image.jpg" alt="image.jpg"></div>'

      page_issues = find_issues(:img_alt_filename, input_html, "page-123")
      assignment_issues = find_issues(:img_alt_filename, input_html, "assignment-456")
      file_issues = find_issues(:img_alt_filename, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end
  end

  context "when fixing image alt text using filenames" do
    it "updates the alt text to a descriptive value" do
      input_html = '<div><img id="test-element" src="image.jpg" alt="image.jpg"></div>'
      fixed_html = fix_issue(:img_alt_filename, input_html, './/img[@id="test-element"]', "Descriptive alt text")

      expect(fixed_html).to include('<img id="test-element" src="image.jpg" alt="Descriptive alt text">')
      expect(fixed_html).not_to include('<img id="test-element" src="image.jpg" alt="image.jpg">')
    end
  end
end
