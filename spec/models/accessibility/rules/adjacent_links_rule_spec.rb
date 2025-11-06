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

describe Accessibility::Rules::AdjacentLinksRule do
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
      expect(Accessibility::Rules::AdjacentLinksRule.new.form(nil).label).to eq("Merge links")
    end
  end

  describe "#issue_preview" do
    let(:rule) { Accessibility::Rules::AdjacentLinksRule.new }

    context "when there are adjacent links with same href" do
      it "returns HTML preview including both links" do
        input_html = '<div><a href="https://example.com">Link 1</a><a href="https://example.com">Link 2</a></div>'
        doc = Nokogiri::HTML::DocumentFragment.parse(input_html)
        extend_nokogiri_with_dom_adapter(doc)
        first_link = doc.at_css("a")

        preview = rule.issue_preview(first_link)

        expect(preview).to include("Link 1")
        expect(preview).to include("Link 2")
        expect(preview).to include('href="https://example.com"')
      end
    end

    context "when there are intermediate nodes between links" do
      it "includes intermediate nodes in the preview" do
        input_html = '<div><a href="https://example.com">Link 1</a> - <a href="https://example.com">Link 2</a></div>'
        doc = Nokogiri::HTML::DocumentFragment.parse(input_html)
        extend_nokogiri_with_dom_adapter(doc)
        first_link = doc.at_css("a")

        preview = rule.issue_preview(first_link)

        expect(preview).to include("Link 1")
        expect(preview).to include(" - ")
        expect(preview).to include("Link 2")
      end
    end

    context "when the element does not have an adjacent link issue" do
      it "returns nil" do
        input_html = '<div><a href="https://example.com">Link 1</a><a href="https://other.com">Link 2</a></div>'
        doc = Nokogiri::HTML::DocumentFragment.parse(input_html)
        extend_nokogiri_with_dom_adapter(doc)
        first_link = doc.at_css("a")
        preview = rule.issue_preview(first_link)

        expect(preview).to be_nil
      end
    end
  end
end
