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

      fixed_html = fix_issue(:table_header_scope, input_html, './/th[@id="test-element"]', I18n.t("The row it's in"))

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "fixes table headers by adding the column scope" do
      input_html = "<table><tr><th id=\"test-element\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"
      expected_html = "<table><tr><th id=\"test-element\" scope=\"col\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"

      fixed_html = fix_issue(:table_header_scope, input_html, './/th[@id="test-element"]', I18n.t("The column it's in"))

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "fixes table headers by adding the row group scope" do
      input_html = "<table><tr><th id=\"test-element\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"
      expected_html = "<table><tr><th id=\"test-element\" scope=\"rowgroup\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"

      fixed_html = fix_issue(:table_header_scope, input_html, './/th[@id="test-element"]', I18n.t("The row group"))

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "fixes table headers by adding the column group scope" do
      input_html = "<table><tr><th id=\"test-element\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"
      expected_html = "<table><tr><th id=\"test-element\" scope=\"colgroup\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"

      fixed_html = fix_issue(:table_header_scope, input_html, './/th[@id="test-element"]', I18n.t("The column group"))

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "does not identify table headers with valid scope attributes" do
      input_html = "<table><tr><th scope=\"col\">Header 1</th><th scope=\"row\">Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      issues = find_issues(:table_header_scope, input_html, "page-123")

      expect(issues).to be_empty
    end

    it "identifies table headers with invalid scope attributes" do
      input_html = "<table><tr><th scope=\"invalid\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"

      issues = find_issues(:table_header_scope, input_html, "page-123")

      expect(issues).not_to be_empty
      expect(issues.first[:element_type]).to eq("th")
    end
  end

  describe "#issue_preview" do
    let(:rule) { described_class.new }

    it "returns highlighted table HTML when element is in a table" do
      html = "<table><tr><th id=\"header1\">Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"
      document = Nokogiri::HTML::DocumentFragment.parse(html)
      extend_nokogiri_with_dom_adapter(document)
      elem = document.at_css("#header1")

      result = rule.issue_preview(elem)

      expect(result).to include("<table>")
      expect(result).to include("outline: 3px solid #000000 !important; outline-offset: -3px !important;")
      expect(result).to include("Header 1")
    end

    it "returns element HTML when element is not in a table" do
      html = "<div><th id=\"orphan\">Orphan Header</th></div>"
      document = Nokogiri::HTML::DocumentFragment.parse(html)
      extend_nokogiri_with_dom_adapter(document)
      elem = document.at_css("#orphan")

      result = rule.issue_preview(elem)

      expect(result).to eq(elem.to_html)
      expect(result).not_to include("outline: 3px solid #000000 !important; outline-offset: -3px !important;")
    end

    it "highlights the correct th element in tables with multiple headers" do
      html = "<table><tr><th>Header 1</th><th id=\"target\">Header 2</th><th>Header 3</th></tr></table>"
      document = Nokogiri::HTML::DocumentFragment.parse(html)
      extend_nokogiri_with_dom_adapter(document)
      elem = document.at_css("#target")

      result = rule.issue_preview(elem)

      result_doc = Nokogiri::HTML::DocumentFragment.parse(result)
      highlighted = result_doc.css("th").select { |th| th["style"]&.include?("outline: 3px solid #000000 !important; outline-offset: -3px !important;") }

      expect(highlighted.first.text).to eq("Header 2")
    end

    it "preserves existing styles when highlighting" do
      html = "<table><tr><th style=\"color: red;\" id=\"styled\">Styled Header</th></tr></table>"
      document = Nokogiri::HTML::DocumentFragment.parse(html)
      extend_nokogiri_with_dom_adapter(document)
      elem = document.at_css("#styled")

      result = rule.issue_preview(elem)

      expect(result).to include("color: red")
      expect(result).to include("outline: 3px solid #000000 !important; outline-offset: -3px !important;")
    end
  end

  describe "#table_preview" do
    let(:rule) { described_class.new }

    it "returns table HTML without highlighting" do
      html = "<table><tr><th id=\"header1\">Header 1</th></tr><tr><td>Data 1</td></tr></table>"
      document = Nokogiri::HTML::DocumentFragment.parse(html)
      extend_nokogiri_with_dom_adapter(document)
      elem = document.at_css("#header1")

      result = rule.send(:table_preview, elem)

      expect(result).to include("<table>")
      expect(result).not_to include("outline: 3px solid #000000 !important; outline-offset: -3px !important;")
      expect(result).to include("Header 1")
    end

    it "returns element HTML when element is not in a table" do
      html = "<div><th id=\"orphan\">Orphan Header</th></div>"
      document = Nokogiri::HTML::DocumentFragment.parse(html)
      extend_nokogiri_with_dom_adapter(document)
      elem = document.at_css("#orphan")

      result = rule.send(:table_preview, elem)

      expect(result).to eq(elem.to_html)
    end
  end
end
