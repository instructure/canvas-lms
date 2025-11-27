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

describe Accessibility::Rules::TableCaptionRule do
  include RuleTestHelper

  context "when testing table captions" do
    it "identifies tables without captions" do
      input_html = "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      issues = find_issues(:table_caption, input_html, "page-123")

      expect(issues).not_to be_empty
      if issues.any?
        expect(issues.first[:element_type]).to eq("table")
      end
    end

    it "calls the correct method on caption" do
      elem = double("Element", tag_name: "table")
      caption = double("Caption", text: "Valid Caption")
      allow(elem).to receive(:query_selector).with("caption").and_return(caption)

      expect(caption).to receive(:text).and_return("Valid Caption")
      expect(caption).not_to receive(:text_content)

      Accessibility::Rules::TableCaptionRule.new.test(elem)
    end

    it "maintains resource-specific isolation between content types" do
      input_html = "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      page_issues = find_issues(:table_caption, input_html, "page-123")
      assignment_issues = find_issues(:table_caption, input_html, "assignment-456")
      file_issues = find_issues(:table_caption, input_html, "file-789")

      if page_issues.any? && assignment_issues.any? && file_issues.any?
        expect(page_issues.first[:data][:id]).to include("page-123")
        expect(assignment_issues.first[:data][:id]).to include("assignment-456")
        expect(file_issues.first[:data][:id]).to include("file-789")
      end
    end
  end

  context "when fixing table captions" do
    it "adds a caption to a table without one" do
      input_html = "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"
      expected_html = "<table><caption>Table description</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      fixed_html = fix_issue(:table_caption, input_html, "./*", "Table description")

      expect(fixed_html.delete("\n")).to eq(expected_html)
    end

    it "updates the caption of a table with an existing caption" do
      input_html = "<table><caption>Table description</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"
      expected_html = "<table><caption>Updated description</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"

      updated_html = fix_issue(:table_caption, input_html, "./*", "Updated description")

      expect(updated_html.delete("\n")).to eq(expected_html)
    end

    it "updates an empty caption with content and returns the table for preview" do
      doc = Nokogiri::HTML::DocumentFragment.parse('<table border="1"><caption></caption><tbody><tr><th>Day</th><th>Mushroom</th></tr><tr><td>Monday</td><td>Morel</td></tr></tbody></table>')
      table_element = doc.at_css("table")
      rule = Accessibility::Rules::TableCaptionRule.new

      result = rule.fix!(table_element, "Weekly Mushroom Schedule")

      expect(result).not_to be_nil
      expect(result).to eq(table_element)
      expect(result.at_css("caption").content).to eq("Weekly Mushroom Schedule")
    end
  end

  context "form" do
    it "returns the proper form" do
      expect(Accessibility::Rules::TableCaptionRule.new.form(nil).label).to eq("Table caption")
    end
  end

  context "when generating fix with LLM" do
    let(:table_element) do
      doc = Nokogiri::HTML::DocumentFragment.parse("<table><thead><tr><th>Header 1</th><th>Header 2</th></tr></thead><tbody><tr><td>Data 1</td><td>Data 2</td></tr><tr><td>Data 3</td><td>Data 4</td></tr><tr><td>Data 5</td><td>Data 6</td></tr><tr><td>Data 7</td><td>Data 8</td></tr><tr><td>Data 9</td><td>Data 10</td></tr><tr><td>Data 11</td><td>Data 12</td></tr></tbody></table>")
      doc.at_css("table")
    end

    let(:mock_llm_config) do
      double("LLMConfig",
             model_id: "test-model-id",
             generate_prompt_and_options: ["Generated prompt", { max_tokens: 500 }])
    end

    let(:mock_inst_llm_client) { double("InstLLM::Client") }

    let(:mock_llm_response) do
      double("InstLLM::Response",
             message: { content: "Generated table caption describing the data" })
    end

    before do
      # Mock LLMConfigs
      allow(LLMConfigs).to receive(:config_for).with("table_caption_generate").and_return(mock_llm_config)

      # Mock InstLLMHelper
      allow(InstLLMHelper).to receive(:client).with("test-model-id").and_return(mock_inst_llm_client)

      # Mock Rails.logger
      allow(Rails.logger).to receive(:error)

      # Ensure the element has the correct tag name
      allow(table_element).to receive(:tag_name).and_return("table")
    end

    context "when LLM config is not found" do
      before do
        allow(LLMConfigs).to receive(:config_for).with("table_caption_generate").and_return(nil)
      end

      it "logs the error and returns nil" do
        expect(Rails.logger).to receive(:error).with(anything)

        result = Accessibility::Rules::TableCaptionRule.new.generate_fix(table_element)
        expect(result).to be_nil
      end
    end

    context "when element is not a table" do
      let(:non_table_element) do
        doc = Nokogiri::HTML::DocumentFragment.parse("<div>Not a table</div>")
        element = doc.at_css("div")
        allow(element).to receive(:tag_name).and_return("div")
        element
      end

      it "logs the error and returns nil" do
        expect(Rails.logger).to receive(:error).with(anything)

        result = Accessibility::Rules::TableCaptionRule.new.generate_fix(non_table_element)
        expect(result).to be_nil
      end
    end

    context "when LLM client succeeds" do
      before do
        allow(mock_inst_llm_client).to receive(:chat).and_return(mock_llm_response)
      end

      it "returns the generated caption content" do
        result = Accessibility::Rules::TableCaptionRule.new.generate_fix(table_element)
        expect(result).to eq("Generated table caption describing the data")
      end

      it "calls the LLM with correct parameters" do
        expect(mock_llm_config).to receive(:generate_prompt_and_options)
          .with(substitutions: { HTML_TABLE: anything })
          .and_return(["Generated prompt", { max_tokens: 500 }])

        expect(mock_inst_llm_client).to receive(:chat)
          .with([{ role: "user", content: "Generated prompt" }])
          .and_return(mock_llm_response)

        Accessibility::Rules::TableCaptionRule.new.generate_fix(table_element)
      end

      it "uses extract_table_preview to limit table size" do
        expect(Accessibility::Rules::TableCaptionRule).to receive(:extract_table_preview)
          .with(table_element)
          .and_call_original

        Accessibility::Rules::TableCaptionRule.new.generate_fix(table_element)
      end
    end

    context "when LLM client raises an error" do
      before do
        allow(mock_inst_llm_client).to receive(:chat).and_raise(StandardError, "API error")
      end

      it "logs the error and returns nil" do
        expect(Rails.logger).to receive(:error).with(anything)

        result = Accessibility::Rules::TableCaptionRule.new.generate_fix(table_element)
        expect(result).to be_nil
      end

      it "handles different types of errors" do
        allow(mock_inst_llm_client).to receive(:chat).and_raise(RuntimeError, "Network timeout")

        expect(Rails.logger).to receive(:error).with(anything)

        result = Accessibility::Rules::TableCaptionRule.new.generate_fix(table_element)
        expect(result).to be_nil
      end
    end

    context "when table has many rows (testing extract_table_preview)" do
      let(:large_table_element) do
        rows = (1..10).map { |i| "<tr><td>Row #{i} Col 1</td><td>Row #{i} Col 2</td></tr>" }.join
        doc = Nokogiri::HTML::DocumentFragment.parse("<table><thead><tr><th>Header 1</th><th>Header 2</th></tr></thead><tbody>#{rows}</tbody></table>")
        doc.at_css("table")
      end

      before do
        allow(large_table_element).to receive(:tag_name).and_return("table")
        allow(mock_inst_llm_client).to receive(:chat).and_return(mock_llm_response)
      end

      it "limits table to first 5 data rows" do
        preview = Accessibility::Rules::TableCaptionRule.extract_table_preview(large_table_element)

        # Should include first 5 rows
        expect(preview.to_html).to include("Row 1 Col 1")
        expect(preview.to_html).to include("Row 5 Col 2")

        # Should not include rows beyond 5
        expect(preview.to_html).not_to include("Row 6 Col 1")
        expect(preview.to_html).not_to include("Row 10 Col 2")
      end

      it "preserves header rows" do
        preview = Accessibility::Rules::TableCaptionRule.extract_table_preview(large_table_element)

        # Headers should always be preserved
        expect(preview.to_html).to include("Header 1")
        expect(preview.to_html).to include("Header 2")
      end

      it "returns a cloned table to avoid modifying original" do
        original_html = large_table_element.to_html
        preview = Accessibility::Rules::TableCaptionRule.extract_table_preview(large_table_element)

        # Original should be unchanged
        expect(large_table_element.to_html).to eq(original_html)
        expect(preview.to_html).not_to eq(original_html)
      end

      it "works with custom row count" do
        preview = Accessibility::Rules::TableCaptionRule.extract_table_preview(large_table_element, 3)

        # Should include first 3 rows
        expect(preview.to_html).to include("Row 1 Col 1")
        expect(preview.to_html).to include("Row 3 Col 2")

        # Should not include rows beyond 3
        expect(preview.to_html).not_to include("Row 4 Col 1")
      end
    end
  end
end
