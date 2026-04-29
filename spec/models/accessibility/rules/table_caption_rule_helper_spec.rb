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

describe Accessibility::Rules::TableCaptionRuleHelper do
  describe ".extract_resource_context" do
    it "extracts context with title and section information" do
      html_content = "<h2>Cellular Biology</h2><p>This section covers cell structure.</p><table><thead><tr><th>Cell Type</th><th>Nucleus</th></tr></thead><tbody><tr><td>Plant</td><td>Yes</td></tr></tbody></table>"
      resource_title = "Biology Lesson"

      context = described_class.extract_resource_context("./table", html_content, resource_title)

      expect(context).to include("Resource Title: Biology Lesson")
      expect(context).to include("Section Title: Cellular Biology")
      expect(context).to include("Section Content: This section covers cell structure.")
    end

    it "works without resource title" do
      html_content = "<h2>Cellular Biology</h2><p>This section covers cell structure.</p><table><thead><tr><th>Cell Type</th><th>Nucleus</th></tr></thead><tbody><tr><td>Plant</td><td>Yes</td></tr></tbody></table>"

      context = described_class.extract_resource_context("./table", html_content, nil)

      expect(context).not_to include("Resource Title:")
      expect(context).to include("Section Title: Cellular Biology")
      expect(context).to include("Section Content: This section covers cell structure.")
    end

    it "works without section information" do
      html_content = "<table><thead><tr><th>Cell Type</th><th>Nucleus</th></tr></thead><tbody><tr><td>Plant</td><td>Yes</td></tr></tbody></table>"
      resource_title = "Biology Lesson"

      context = described_class.extract_resource_context("./table", html_content, resource_title)

      expect(context).to eq("Resource Title: Biology Lesson")
    end

    it "returns empty string when no context available" do
      html_content = "<table><thead><tr><th>Cell Type</th><th>Nucleus</th></tr></thead><tbody><tr><td>Plant</td><td>Yes</td></tr></tbody></table>"

      context = described_class.extract_resource_context("./table", html_content, nil)

      expect(context).to eq("")
    end
  end

  describe ".extract_latest_section_before" do
    it "extracts section context from HTML content" do
      html_content = "<h2>Cellular Biology</h2><p>This section covers cell structure.</p><table><thead><tr><th>Cell Type</th><th>Nucleus</th></tr></thead><tbody><tr><td>Plant</td><td>Yes</td></tr></tbody></table>"

      section_info = described_class.extract_latest_section_before("./table", html_content)

      expect(section_info).not_to be_nil
      expect(section_info[:title]).to eq("Cellular Biology")
      expect(section_info[:content]).to eq("This section covers cell structure.")
    end

    it "handles multiple tables and selects correct one by index" do
      html_content = "<h2>First Section</h2><p>First content.</p><table><tr><td>Table 1</td></tr></table><h2>Second Section</h2><p>Second content.</p><table><tr><td>Table 2</td></tr></table>"

      section_info = described_class.extract_latest_section_before("./table[2]", html_content)

      expect(section_info).not_to be_nil
      expect(section_info[:title]).to eq("Second Section")
      expect(section_info[:content]).to eq("Second content.")
    end

    it "truncates content to 500 characters" do
      long_content = "a" * 600
      html_content = "<h2>Section</h2><p>#{long_content}</p><table><tr><td>Data</td></tr></table>"

      section_info = described_class.extract_latest_section_before("./table", html_content)

      expect(section_info[:content].length).to be <= 500
      expect(section_info[:content]).to end_with("...")
    end
  end

  describe ".build_system_prompt" do
    it "returns the system prompt" do
      prompt = described_class.build_system_prompt

      expect(prompt).to include("Web Accessibility")
      expect(prompt).to include("Educational Content Design")
    end
  end

  describe ".build_user_message" do
    it "includes context and table HTML" do
      context = "Resource Title: Test\nSection Title: Biology"
      table_html = "<table><tr><td>Data</td></tr></table>"

      message = described_class.build_user_message(context, table_html)

      expect(message).to include(context)
      expect(message).to include(table_html)
      expect(message).to include("Step-by-Step Logic")
    end
  end

  describe ".extract_table_preview" do
    let(:large_table_element) do
      rows = (1..10).map { |i| "<tr><td>Row #{i} Col 1</td><td>Row #{i} Col 2</td></tr>" }.join
      doc = Nokogiri::HTML::DocumentFragment.parse("<table><thead><tr><th>Header 1</th><th>Header 2</th></tr></thead><tbody>#{rows}</tbody></table>")
      doc.at_css("table")
    end

    before do
      allow(large_table_element).to receive(:tag_name).and_return("table")
    end

    it "limits table to first 5 data rows" do
      preview = described_class.extract_table_preview(large_table_element)

      # Should include first 5 rows
      expect(preview.to_html).to include("Row 1 Col 1")
      expect(preview.to_html).to include("Row 5 Col 2")

      # Should not include rows beyond 5
      expect(preview.to_html).not_to include("Row 6 Col 1")
      expect(preview.to_html).not_to include("Row 10 Col 2")
    end

    it "preserves header rows" do
      preview = described_class.extract_table_preview(large_table_element)

      # Headers should always be preserved
      expect(preview.to_html).to include("Header 1")
      expect(preview.to_html).to include("Header 2")
    end

    it "returns a cloned table to avoid modifying original" do
      original_html = large_table_element.to_html
      preview = described_class.extract_table_preview(large_table_element)

      # Original should be unchanged
      expect(large_table_element.to_html).to eq(original_html)
      expect(preview.to_html).not_to eq(original_html)
    end

    it "works with custom row count" do
      preview = described_class.extract_table_preview(large_table_element, 3)

      # Should include first 3 rows
      expect(preview.to_html).to include("Row 1 Col 1")
      expect(preview.to_html).to include("Row 3 Col 2")

      # Should not include rows beyond 3
      expect(preview.to_html).not_to include("Row 4 Col 1")
    end
  end
end
