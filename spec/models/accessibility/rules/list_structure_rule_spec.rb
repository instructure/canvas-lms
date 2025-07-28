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

describe Accessibility::Rules::ListStructureRule do
  include RuleTestHelper

  context "when testing list structure" do
    it "identifies improper list structures" do
      input_html = "<p>- Elem 1\n- Elem 2\n- Elem 3</p>"

      issues = find_issues(:list_structure, input_html, "page-123")

      expect(issues).not_to be_empty
    end
  end

  context "when updating list structure" do
    it "returns same element" do
      input_html = "<p>Normal Paragraph</p>"
      expected_html = "<p>Normal Paragraph</p>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Resolves ordered items with followed by a period" do
      input_html = "<p>1. List</p><p>2. List</p><p>3. List</p>"
      expected_html = "<ol><li>List</li><li>List</li><li>List</li></ol>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Resolves ordered items with followed by parentheses" do
      input_html = "<p>1) List</p><p>2) List</p><p>3) List</p>"
      expected_html = "<ol><li>List</li><li>List</li><li>List</li></ol>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Resolves unordered items with preceded by an asterisk" do
      input_html = "<p>* List</p><p>* List</p><p>* List</p>"
      expected_html = "<ul><li>List</li><li>List</li><li>List</li></ul>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Resolves unordered items with preceded by a hyphen" do
      input_html = "<p>- List</p><p>- List</p><p>- List</p>"
      expected_html = "<ul><li>List</li><li>List</li><li>List</li></ul>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Resolves ordered with a start attribute" do
      input_html = "<p>3. List</p><p>4. List</p><p>5. List</p>"
      expected_html = '<ol start="3"><li>List</li><li>List</li><li>List</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Replaces the ordered part of the list even when nested in an element" do
      input_html = "<p><strong>1. Text</strong> Text</p><p><strong>2. Text</strong> Text</p><p><strong>3. Text</strong> Text</p>"
      expected_html = "<ol><li><strong>Text</strong> Text</li><li><strong>Text</strong> Text</li><li><strong>Text</strong> Text</li></ol>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Replaces bullets/numbers even when it is not in the first child" do
      input_html = '<p><img src="a.jpg">1. List</p><p><img src="b.jpg">2. List</p><p><img src="c.jpg">3. List</p>'
      expected_html = '<ol><li><img src="a.jpg">List</li><li><img src="b.jpg">List</li><li><img src="c.jpg">List</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Stops creating list items if a paragraph is not list-like" do
      input_html = "<p>1. List</p><p>2. List</p><p>Normal Paragraph</p>"
      expected_html = "<ol><li>List</li><li>List</li></ol><p>Normal Paragraph</p>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Splits paragraphs by <br>" do
      input_html = "<p>1. List <br> 2. List</p><p>3. List</p><p>4. List</p>"
      expected_html = "<ol><li>List</li><li>List</li><li>List</li><li>List</li></ol>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end
  end

  context "rootNode" do
    it "returns the parentNode of an element" do
      input_html = "<p>Normal Paragraph</p>"
      expected_html = "<p>Normal Paragraph</p>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end
  end

  context "message" do
    it "returns the proper message" do
      input_html = "<p>Normal Paragraph</p>"
      expected_html = "<p>Normal Paragraph</p>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end
  end

  context "why" do
    it "returns the proper why message" do
      input_html = "<p>Normal Paragraph</p>"
      expected_html = "<p>Normal Paragraph</p>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end
  end

  context "linkText" do
    it "returns the proper linkText message" do
      input_html = "<p>Normal Paragraph</p>"
      expected_html = "<p>Normal Paragraph</p>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end
  end

  context "form" do
    it "returns the proper form" do
      expect(Accessibility::Rules::ListStructureRule.form(nil).label).to eq("Format as list")
    end
  end
end
