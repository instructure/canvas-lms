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

describe Accessibility::ContentLoader do
  let(:context) { double("Context") }
  let(:assignment_id) { 1 }
  let(:page_id) { 2 }
  let(:assignment_content) { "<div><h1>Assignment Title</h1><p>Assignment description</p></div>" }
  let(:page_content) { "<div><h2>Page Title</h2><p>Page body content</p></div>" }

  describe "#content" do
    context "for Assignments" do
      let(:content_loader) { described_class.new(context:, type: "Assignment", id: assignment_id) }
      let(:assignments_double) { double("Assignments") }
      let(:assignment) { double("Assignment", description: assignment_content) }

      before do
        allow(context).to receive(:assignments).and_return(assignments_double)
      end

      context "when assignment exists" do
        before do
          allow(assignments_double).to receive(:exists?).with(assignment_id).and_return(true)
          allow(assignments_double).to receive(:find_by).with(id: assignment_id).and_return(assignment)
        end

        it "returns assignment description with ok status" do
          result = content_loader.content

          expect(result[:status]).to eq(:ok)
          expect(result[:json][:content]).to eq(assignment_content)
        end
      end

      context "when assignment does not exist" do
        before do
          allow(assignments_double).to receive(:exists?).with(assignment_id).and_return(false)
        end

        it "returns not found error" do
          result = content_loader.content

          expect(result[:status]).to eq(:not_found)
          expect(result[:json][:error]).to eq("Resource 'Assignment' with id '#{assignment_id}' was not found.")
        end
      end
    end

    context "for Pages" do
      let(:content_loader) { described_class.new(context:, type: "Page", id: page_id) }
      let(:wiki_pages_double) { double("WikiPages") }
      let(:page) { double("Page", body: page_content) }

      before do
        allow(context).to receive(:wiki_pages).and_return(wiki_pages_double)
      end

      context "when page exists" do
        before do
          allow(wiki_pages_double).to receive(:exists?).with(page_id).and_return(true)
          allow(wiki_pages_double).to receive(:find_by).with(id: page_id).and_return(page)
        end

        it "returns page body with ok status" do
          result = content_loader.content

          expect(result[:status]).to eq(:ok)
          expect(result[:json][:content]).to eq(page_content)
        end
      end

      context "when page does not exist" do
        before do
          allow(wiki_pages_double).to receive(:exists?).with(page_id).and_return(false)
        end

        it "returns not found error" do
          result = content_loader.content

          expect(result[:status]).to eq(:not_found)
          expect(result[:json][:error]).to eq("Resource 'Page' with id '#{page_id}' was not found.")
        end
      end
    end

    context "for unknown content type" do
      let(:content_loader) { described_class.new(context:, type: "UnknownType", id: 1) }

      it "returns unprocessable entity error" do
        result = content_loader.content

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:json][:error]).to eq("Unknown content type: UnknownType")
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with("Unknown content type: UnknownType")

        content_loader.content
      end
    end
  end

  describe "#extract_element_from_content" do
    let(:content_loader) { described_class.new(context:, type: "Page", id: page_id) }
    let(:wiki_pages_double) { double("WikiPages") }
    let(:page) { double("Page", body: page_content) }
    let(:xpath) { ".//h2" }

    before do
      allow(context).to receive(:wiki_pages).and_return(wiki_pages_double)
      allow(wiki_pages_double).to receive(:exists?).with(page_id).and_return(true)
      allow(wiki_pages_double).to receive(:find_by).with(id: page_id).and_return(page)
    end

    context "when element exists in content" do
      it "returns the element's HTML" do
        result = content_loader.extract_element_from_content(".//h2")

        expect(result[:status]).to eq(:ok)
        expect(result[:json][:content]).to eq("<h2>Page Title</h2>")
      end

      it "returns the first h2 element specifically" do
        result = content_loader.extract_element_from_content(".//h2[1]")

        expect(result[:status]).to eq(:ok)
        expect(result[:json][:content]).to eq("<h2>Page Title</h2>")
      end

      it "returns paragraph content" do
        result = content_loader.extract_element_from_content(".//p")

        expect(result[:status]).to eq(:ok)
        expect(result[:json][:content]).to eq("<p>Page body content</p>")
      end

      it "returns div content with all children" do
        result = content_loader.extract_element_from_content(".//div")

        expect(result[:status]).to eq(:ok)
        expect(result[:json][:content]).to eq("<div><h2>Page Title</h2><p>Page body content</p></div>")
      end
    end

    context "when element does not exist in content" do
      let(:xpath) { ".//nonexistent" }

      it "returns element not found error" do
        result = content_loader.extract_element_from_content(xpath)

        expect(result[:status]).to eq(:not_found)
        expect(result[:json][:error]).to eq("Element not found")
      end
    end

    context "when path is nil" do
      it "returns full content when path is nil" do
        result = content_loader.extract_element_from_content(nil)

        expect(result[:status]).to eq(:ok)
        expect(result[:json][:content]).to eq(page_content)
      end
    end

    context "when content loading fails" do
      before do
        allow(wiki_pages_double).to receive(:exists?).with(page_id).and_return(false)
      end

      it "returns the content error without trying to extract element" do
        result = content_loader.extract_element_from_content(xpath)

        expect(result[:status]).to eq(:not_found)
        expect(result[:json][:error]).to eq("Resource 'Page' with id '#{page_id}' was not found.")
      end
    end

    context "with empty content" do
      let(:empty_content) { "" }
      let(:page) { double("Page", body: empty_content) }

      it "handles empty content" do
        xpath = "//p"
        result = content_loader.extract_element_from_content(xpath)

        expect(result[:status]).to eq(:not_found)
        expect(result[:json][:error]).to eq("Element not found")
      end
    end
  end

  describe "#initialize" do
    it "sets instance variables correctly" do
      content_loader = described_class.new(context:, type: "Page", id: 123)

      expect(content_loader.instance_variable_get(:@context)).to eq(context)
      expect(content_loader.instance_variable_get(:@type)).to eq("Page")
      expect(content_loader.instance_variable_get(:@id)).to eq(123)
    end
  end
end
