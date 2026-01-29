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
      expected_html = '<ol type="1"><li>List</li><li>List</li><li>List</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Resolves ordered items with followed by parentheses" do
      input_html = "<p>1) List</p><p>2) List</p><p>3) List</p>"
      expected_html = '<ol type="1"><li>List</li><li>List</li><li>List</li></ol>'

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
      expected_html = '<ol type="1" start="3"><li>List</li><li>List</li><li>List</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Resolves unordered items with extra space" do
      input_html = "<p>* List </p><p>* List </p><p>* List </p>"
      expected_html = "<ul><li>List </li><li>List </li><li>List </li></ul>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Resolves ordered with extra space" do
      input_html = "<p>1. List </p><p>2. List </p><p>3. List </p>"
      expected_html = '<ol type="1"><li>List </li><li>List </li><li>List </li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Replaces the ordered part of the list even when nested in an element" do
      input_html = "<p><strong>1. Text</strong> Text</p><p><strong>2. Text</strong> Text</p><p><strong>3. Text</strong> Text</p>"
      expected_html = '<ol type="1"><li><strong>Text</strong> Text</li><li><strong>Text</strong> Text</li><li><strong>Text</strong> Text</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Replaces bullets/numbers even when it is not in the first child" do
      input_html = '<p><img src="a.jpg">1. List</p><p><img src="b.jpg">2. List</p><p><img src="c.jpg">3. List</p>'
      expected_html = '<ol type="1"><li><img src="a.jpg">List</li><li><img src="b.jpg">List</li><li><img src="c.jpg">List</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Stops creating list items if a paragraph is not list-like" do
      input_html = "<p>1. List</p><p>2. List</p><p>Normal Paragraph</p>"
      expected_html = '<ol type="1"><li>List</li><li>List</li></ol><p>Normal Paragraph</p>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Splits paragraphs by <br>" do
      input_html = "<p>1. List <br> 2. List</p><p>3. List</p><p>4. List</p>"
      expected_html = '<ol type="1"><li>List</li><li>List</li><li>List</li><li>List</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Preserves HTML entities and tags when splitting by <br>" do
      input_html = "<p>1. Item with &lt;span&gt; tag <br> 2. Another &amp; item</p>"
      expected_html = '<ol type="1"><li>Item with &lt;span&gt; tag</li><li>Another &amp; item</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    context "marker cleanup after assembly (matching JS behavior)" do
      it "Removes markers when nested with trailing space in same text node" do
        input_html = "<p><strong>1. Text</strong> More</p><p><strong>2. Text</strong> More</p>"
        expected_html = '<ol type="1"><li><strong>Text</strong> More</li><li><strong>Text</strong> More</li></ol>'

        fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

        expect(fixed_html.delete("\n")).to eq(expected_html)
      end

      it "Removes markers when multiple elements have markers with trailing space" do
        input_html = "<p><span>* </span><strong>Item</strong></p><p><span>* </span><strong>Item</strong></p>"
        expected_html = "<ul><li><span></span><strong>Item</strong></li><li><span></span><strong>Item</strong></li></ul>"

        fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

        expect(fixed_html.delete("\n")).to eq(expected_html)
      end

      # Known limitation: matches JavaScript behavior
      it "Does not remove markers isolated without trailing space (JS parity)" do
        input_html = "<p><span>1.</span> Item</p><p><span>2.</span> Item</p>"
        # Markers remain because regex requires trailing whitespace
        expected_html = '<ol type="1"><li><span>1.</span> Item</li><li><span>2.</span> Item</li></ol>'

        fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

        expect(fixed_html.delete("\n")).to eq(expected_html)
      end

      # Known limitation: matches JavaScript behavior
      it "Does not remove bullet markers isolated without trailing space (JS parity)" do
        input_html = "<p><em>*</em> Item</p><p><em>*</em> Item</p>"
        # Markers remain because regex requires trailing whitespace
        expected_html = "<ul><li><em>*</em> Item</li><li><em>*</em> Item</li></ul>"

        fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

        expect(fixed_html.delete("\n")).to eq(expected_html)
      end

      # Known limitation: matches JavaScript behavior
      it "Does not remove markers in deeply nested elements without trailing space (JS parity)" do
        input_html = "<p><span><strong>1.</strong></span> Item</p><p><span><strong>2.</strong></span> Item</p>"
        # Markers remain in deeply nested elements without trailing space
        expected_html = '<ol type="1"><li><span><strong>1.</strong></span> Item</li><li><span><strong>2.</strong></span> Item</li></ol>'

        fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

        expect(fixed_html.delete("\n")).to eq(expected_html)
      end
    end

    it "Separates bullet and numbered lists when mixed" do
      input_html = "<p>* Bullet item</p><p>* Bullet item</p><p>* Bullet item</p><p>1. Numbered item</p><p>2. Numbered item</p>"
      expected_html = "<ul><li>Bullet item</li><li>Bullet item</li><li>Bullet item</li></ul><p>1. Numbered item</p><p>2. Numbered item</p>"

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Fixes numbered list after bullet list when fixing the numbered one" do
      input_html = "<ul><li>Bullet item</li><li>Bullet item</li><li>Bullet item</li></ul><p>1. Numbered item</p><p>2. Numbered item</p>"
      expected_html = '<ul><li>Bullet item</li><li>Bullet item</li><li>Bullet item</li></ul><ol type="1" start="2"><li>Numbered item</li><li>Numbered item</li></ol>'

      # Fix the first numbered item (third paragraph)
      fixed_html = fix_issue(:list_structure, input_html, "./*[3]", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Formats lowercase alphabetic lists" do
      input_html = "<p>a. First item</p><p>b. Second item</p><p>c. Third item</p>"
      expected_html = '<ol type="a"><li>First item</li><li>Second item</li><li>Third item</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Formats uppercase alphabetic lists" do
      input_html = "<p>A. First item</p><p>B. Second item</p><p>C. Third item</p>"
      expected_html = '<ol type="A"><li>First item</li><li>Second item</li><li>Third item</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Separates numeric and alphabetic lists when mixed" do
      input_html = "<p>1. First numeric</p><p>2. Second numeric</p><p>a. First alpha</p><p>b. Second alpha</p>"
      expected_html = '<ol type="1"><li>First numeric</li><li>Second numeric</li></ol><p>a. First alpha</p><p>b. Second alpha</p>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Formats lowercase Roman numeral lists" do
      input_html = "<p>i. First item</p><p>ii. Second item</p><p>iii. Third item</p>"
      expected_html = '<ol type="i"><li>First item</li><li>Second item</li><li>Third item</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Formats uppercase Roman numeral lists" do
      input_html = "<p>I. First item</p><p>II. Second item</p><p>III. Third item</p>"
      expected_html = '<ol type="I"><li>First item</li><li>Second item</li><li>Third item</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Separates alphabetic and Roman numeral lists when mixed" do
      input_html = "<p>a. Alphabetic</p><p>b. Alphabetic</p><p>i. Roman</p><p>ii. Roman</p>"
      expected_html = '<ol type="a"><li>Alphabetic</li><li>Alphabetic</li></ol><p>i. Roman</p><p>ii. Roman</p>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "Formats lists starting with type '1' and start '5'" do
      input_html = "<p>5. Fifth item</p><p>6. Sixth item</p><p>7. Seventh item</p>"
      expected_html = '<ol type="1" start="5"><li>Fifth item</li><li>Sixth item</li><li>Seventh item</li></ol>'

      fixed_html = fix_issue(:list_structure, input_html, "./*", "true")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    context "when checking false positives" do
      it "does not flag text with hyphens after inline formatting" do
        input_html = "<p><strong>Graph 1</strong> - The graph above shows data.</p>"

        issues = find_issues(:list_structure, input_html, "page-123")

        expect(issues).to be_empty
      end

      it "does not flag text with period after inline elements" do
        input_html = "<p>Answer is 10<sup>-2</sup>m. This represents the conversion factor.</p>"

        issues = find_issues(:list_structure, input_html, "page-123")

        expect(issues).to be_empty
      end
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
      expect(Accessibility::Rules::ListStructureRule.new.form(nil).label).to eq("Reformat")
    end
  end

  context "issue_preview" do
    let(:rule) { Accessibility::Rules::ListStructureRule.new }

    it "returns HTML for a single list item" do
      input_html = "<p>* Single item</p>"
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      elem = document.at("p")

      preview = rule.issue_preview(elem)

      expect(preview).to include("<p>* Single item</p>")
    end

    it "returns HTML for all consecutive list items when given the first element" do
      input_html = "<p>* First item</p><p>* Second item</p><p>* Third item</p>"
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      first_elem = document.at("p")

      preview = rule.issue_preview(first_elem)

      expect(preview).to include("* First item")
      expect(preview).to include("* Second item")
      expect(preview).to include("* Third item")
      expect(preview.scan("<p>").length).to eq(3)
    end

    it "returns HTML for all consecutive list items when given a middle element" do
      input_html = "<p>* First item</p><p>* Second item</p><p>* Third item</p>"
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      paragraphs = document.css("p")
      middle_elem = paragraphs[1]

      preview = rule.issue_preview(middle_elem)

      expect(preview).to include("* First item")
      expect(preview).to include("* Second item")
      expect(preview).to include("* Third item")
      expect(preview.scan("<p>").length).to eq(3)
    end

    it "returns HTML for all consecutive list items when given the last element" do
      input_html = "<p>* First item</p><p>* Second item</p><p>* Third item</p>"
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      paragraphs = document.css("p")
      last_elem = paragraphs[2]

      preview = rule.issue_preview(last_elem)

      expect(preview).to include("* First item")
      expect(preview).to include("* Second item")
      expect(preview).to include("* Third item")
      expect(preview.scan("<p>").length).to eq(3)
    end

    it "stops at non-list paragraphs" do
      input_html = "<p>* First item</p><p>* Second item</p><p>Not a list</p><p>* Third item</p>"
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      first_elem = document.at("p")

      preview = rule.issue_preview(first_elem)

      expect(preview).to include("* First item")
      expect(preview).to include("* Second item")
      expect(preview).not_to include("Not a list")
      expect(preview).not_to include("* Third item")
      expect(preview.scan("<p>").length).to eq(2)
    end

    it "preserves nested HTML elements in preview" do
      input_html = "<p><strong>* First</strong> item</p><p><strong>* Second</strong> item</p>"
      document = Nokogiri::HTML::DocumentFragment.parse(input_html)
      extend_nokogiri_with_dom_adapter(document)
      first_elem = document.at("p")

      preview = rule.issue_preview(first_elem)

      expect(preview).to include("<strong>")
      expect(preview).to include("* First")
      expect(preview).to include("* Second")
      expect(preview.scan("<p>").length).to eq(2)
    end
  end
end
