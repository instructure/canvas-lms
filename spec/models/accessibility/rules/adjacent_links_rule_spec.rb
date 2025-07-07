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

RSpec.describe "AdjacentLinksRule", type: :feature do
  include RuleTestHelper

  context "when testing adjacent links" do
    it "identifies adjacent links with the same URL" do
      input_html = '<div><a href="https://example.com">Link 1</a> <a href="https://example.com">Link 2</a></div>'

      issues = find_issues(:adjacent_links, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("a")
      end
    end

    it "do not identifies adjecent links with different URLs" do
      input_html = '<div><a href="https://example1.com">Link 1</a> <a href="https://example2.com">Link 2</a></div>'

      issues = find_issues(:adjacent_links, input_html, "page-123")

      expect(issues).to be_empty
    end
  end

  context "when fixing adjacent links" do
    it "merges adjacent links with the same URL" do
      input_html = '<div><a id="test-link" href="https://example.com">Link 1</a> <a href="https://example.com">Link 2</a></div>'
      fixed_html = fix_issue(:adjacent_links, input_html, ".//a[@id='test-link']", "true")

      expect(fixed_html).to include('<a id="test-link" href="https://example.com">Link 1 Link 2</a>')
      expect(fixed_html).not_to include('<a id="test-link" href="https://example.com">Link 2</a>')
    end
  end

  context "form" do
    it "merges adjacent links with the same URL" do
      expect(Accessibility::Rules::AdjacentLinksRule.form(nil).label).to eq("Merge links")
    end
  end
end
