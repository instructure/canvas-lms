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
  include Factories

  let(:course) { course_model }
  let(:assignment) { assignment_model(course:, description: assignment_content) }
  let(:wiki_page) { wiki_page_model(course:, title: "Test Page", body: page_content) }
  let(:discussion_topic) { discussion_topic_model(context: course, message: discussion_content) }
  let(:assignment_content) { "<div><h1>Assignment Title</h1><p>Assignment description</p></div>" }
  let(:page_content) { "<div><h2>Page Title</h2><p>Page body content</p></div>" }
  let(:discussion_content) { "<div><h3>Discussion Title</h3><p>Discussion message</p></div>" }

  describe "#content" do
    context "for Assignments" do
      let!(:issue) { accessibility_issue_model(course:, context: assignment, node_path: nil) }
      let(:content_loader) { described_class.new(issue_id: issue.id) }

      it "returns assignment description" do
        result = content_loader.content

        expect(result).to eq({ content: assignment_content, metadata: {} })
      end
    end

    context "for Pages" do
      let!(:issue) { accessibility_issue_model(course:, context: wiki_page, node_path: nil) }
      let(:content_loader) { described_class.new(issue_id: issue.id) }

      it "returns page body" do
        result = content_loader.content

        expect(result).to eq({ content: page_content, metadata: {} })
      end
    end

    context "for DiscussionTopics" do
      let!(:issue) { accessibility_issue_model(course:, context: discussion_topic, node_path: nil) }
      let(:content_loader) { described_class.new(issue_id: issue.id) }

      it "returns discussion topic message" do
        result = content_loader.content

        expect(result).to eq({ content: discussion_content, metadata: {} })
      end
    end

    context "for unknown content type" do
      let!(:issue) { accessibility_issue_model(course:, context: wiki_page, node_path: nil) }
      let(:content_loader) { described_class.new(issue_id: issue.id) }

      it "raises UnsupportedResourceTypeError" do
        # Mock the resource to simulate an unsupported type
        allow(content_loader).to receive(:resource_html_content).and_raise(
          Accessibility::ContentLoader::UnsupportedResourceTypeError.new("Unsupported resource type: Course")
        )

        expect do
          content_loader.content
        end.to raise_error(Accessibility::ContentLoader::UnsupportedResourceTypeError, "Unsupported resource type: Course")
      end
    end
  end

  describe "#extract_element_from_content" do
    let!(:issue) { accessibility_issue_model(course:, context: wiki_page, node_path: xpath) }
    let(:content_loader) { described_class.new(issue_id: issue.id) }

    context "when element exists in content" do
      let(:xpath) { ".//h2" }

      it "returns the element's HTML" do
        result = content_loader.content

        expect(result).to eq({ content: "<h2>Page Title</h2>", metadata: {} })
      end
    end

    context "when extracting first h2 element specifically" do
      let(:xpath) { ".//h2[1]" }

      it "returns the first h2 element" do
        result = content_loader.content

        expect(result).to eq({ content: "<h2>Page Title</h2>", metadata: {} })
      end
    end

    context "when extracting paragraph content" do
      let(:xpath) { ".//p" }

      it "returns paragraph content" do
        result = content_loader.content

        expect(result).to eq({ content: "<p>Page body content</p>", metadata: {} })
      end
    end

    context "when extracting from discussion topic" do
      let!(:issue) { accessibility_issue_model(course:, context: discussion_topic, node_path: xpath) }
      let(:content_loader) { described_class.new(issue_id: issue.id) }
      let(:xpath) { ".//h3" }

      it "returns discussion topic element" do
        result = content_loader.content

        expect(result).to eq({ content: "<h3>Discussion Title</h3>", metadata: {} })
      end
    end

    context "when extracting div content with all children" do
      let(:xpath) { ".//div" }

      it "returns div content with all children" do
        result = content_loader.content

        expect(result).to eq({ content: "<div><h2>Page Title</h2><p>Page body content</p></div>", metadata: {} })
      end
    end

    context "when element does not exist in content" do
      let(:xpath) { ".//nonexistent" }

      it "raises ElementNotFoundError" do
        expect do
          content_loader.content
        end.to raise_error(Accessibility::ContentLoader::ElementNotFoundError, /Element not found at path/)
      end
    end

    context "when path is nil" do
      let(:xpath) { nil }

      it "returns full content" do
        result = content_loader.content

        expect(result).to eq({ content: page_content, metadata: {} })
      end
    end

    context "when path is empty string" do
      let(:xpath) { "" }

      it "returns full content" do
        result = content_loader.content

        expect(result).to eq({ content: page_content, metadata: {} })
      end
    end

    context "with empty content" do
      let(:empty_content) { "" }
      let(:wiki_page) { wiki_page_model(course:, title: "Empty Page", body: empty_content) }
      let(:xpath) { "//p" }

      it "raises ElementNotFoundError" do
        expect do
          content_loader.content
        end.to raise_error(Accessibility::ContentLoader::ElementNotFoundError)
      end
    end
  end

  describe "#initialize" do
    let!(:issue) { accessibility_issue_model(course:, context: wiki_page, rule_type: "img-alt", node_path: ".//div") }

    it "sets instance variables correctly" do
      content_loader = described_class.new(issue_id: issue.id)

      expect(content_loader.instance_variable_get(:@issue)).to eq(issue)
      expect(content_loader.instance_variable_get(:@resource)).to eq(wiki_page)
      expect(content_loader.instance_variable_get(:@rule_id)).to eq("img-alt")
      expect(content_loader.instance_variable_get(:@path)).to eq(".//div")
    end
  end

  describe "issue preview with rule_id" do
    let(:test_content) do
      "<html><body><div><h1>Test Element</h1></div></body></html>"
    end
    let(:wiki_page) { wiki_page_model(course:, title: "Test Page", body: test_content) }
    let(:mock_rule_instance) { double("RuleInstance") }
    let(:mock_rule_registry) { { "img-alt" => mock_rule_instance } }

    context "when rule_id is provided and rule exists" do
      let!(:issue) { accessibility_issue_model(course:, context: wiki_page, rule_type: "img-alt", node_path: ".//h1") }
      let(:content_loader) { described_class.new(issue_id: issue.id) }

      before do
        allow(Accessibility::Rule).to receive(:registry).and_return(mock_rule_registry)
      end

      it "uses the rule's issue_preview method to generate preview" do
        allow(mock_rule_instance).to receive(:issue_preview).and_return("<h1>Test Element</h1><p>Extra context</p>")

        result = content_loader.content

        expect(mock_rule_instance).to have_received(:issue_preview)
        expect(result).to eq({ content: "<h1>Test Element</h1><p>Extra context</p>", metadata: {} })
      end
    end

    context "when rule_id is provided but rule does not exist" do
      let!(:issue) { accessibility_issue_model(course:, context: wiki_page, rule_type: "img-alt", node_path: ".//h1") }
      let(:content_loader) { described_class.new(issue_id: issue.id) }

      before do
        allow(Accessibility::Rule).to receive(:registry).and_return({})
      end

      it "falls back to returning the element's HTML" do
        result = content_loader.content

        expect(result).to eq({ content: "<h1>Test Element</h1>", metadata: {} })
      end
    end

    context "when rule_id is not provided" do
      let!(:issue) { accessibility_issue_model(course:, context: wiki_page, rule_type: "img-alt", node_path: ".//h1") }
      let(:content_loader) { described_class.new(issue_id: issue.id) }

      it "returns the element's HTML without using issue_preview" do
        result = content_loader.content

        expect(result).to eq({ content: "<h1>Test Element</h1>", metadata: {} })
      end
    end

    context "when rule's issue_preview returns nil" do
      let!(:issue) { accessibility_issue_model(course:, context: wiki_page, rule_type: "img-alt", node_path: ".//h1") }
      let(:content_loader) { described_class.new(issue_id: issue.id) }

      before do
        allow(Accessibility::Rule).to receive(:registry).and_return(mock_rule_registry)
      end

      it "falls back to element's HTML when issue_preview returns nil" do
        allow(mock_rule_instance).to receive(:issue_preview).and_return(nil)

        result = content_loader.content

        expect(mock_rule_instance).to have_received(:issue_preview)
        expect(result).to eq({ content: "<h1>Test Element</h1>", metadata: {} })
      end
    end
  end
end
