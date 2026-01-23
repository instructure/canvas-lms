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

describe Accessibility::Issue::HtmlFixer do
  let(:course) { course_model }

  describe "#apply_fix!" do
    let(:wiki_page) { wiki_page_model(course:, title: "Test Page", body: "<div><h1>Page Title</h1></div>") }

    context "when resource type is invalid" do
      let(:html_fixer) do
        described_class.new(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "invalid_resource",
          "./div/h1",
          "Change it to Heading 2"
        )
      end

      it "raises an error" do
        expect do
          html_fixer.apply_fix!
        end.to raise_error(ArgumentError, "Unsupported resource type: String")
      end
    end

    context "when fix fails" do
      let(:html_fixer) do
        described_class.new(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          wiki_page,
          "invalid_path",
          "Change it to Heading 2"
        )
      end

      it "returns an error" do
        result = html_fixer.apply_fix!

        expect(result).to eq(
          {
            status: :bad_request,
            json: {
              error: "Element not found for path: invalid_path"
            },
          }
        )
      end
    end

    context "when fix succeeds" do
      let(:html_fixer) do
        described_class.new(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          wiki_page,
          "./div/h1",
          "Change it to Heading 2"
        )
      end

      it "updates the resource successfully" do
        html_fixer.apply_fix!

        expect(wiki_page.reload.body).to eq "<div><h2>Page Title</h2></div>"
      end

      it "returns the full document with the fix applied" do
        result = html_fixer.apply_fix!

        expect(result).to eq(
          {
            status: :ok,
            json: {
              success: true
            },
          }
        )
      end

      it "does not trigger accessibility scan when saving the fix" do
        wiki_page

        account = course.root_account
        account.enable_feature!(:a11y_checker)
        course.enable_feature!(:a11y_checker_eap)

        expect(Accessibility::ResourceScannerService).not_to receive(:call)

        html_fixer.apply_fix!
      end
    end

    context "with a discussion topic" do
      let(:discussion_topic) { discussion_topic_model(context: course, message: "<div><h1>Discussion Title</h1></div>") }

      let(:html_fixer) do
        described_class.new(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          discussion_topic,
          "./div/h1",
          "Change it to Heading 2"
        )
      end

      it "updates the resource successfully" do
        html_fixer.apply_fix!

        expect(discussion_topic.reload.message).to eq "<div><h2>Discussion Title</h2></div>"
      end

      it "returns the full document with the fix applied" do
        result = html_fixer.apply_fix!

        expect(result).to eq(
          {
            status: :ok,
            json: {
              success: true
            },
          }
        )
      end
    end
  end

  describe "#preview_fix" do
    context "with a wiki page" do
      let(:wiki_page) { wiki_page_model(course:, title: "Test Page", body: "<div><h1>Page Title</h1></div>") }

      context "with element_only: false (full document)" do
        context "when fix fails" do
          let(:html_fixer) do
            described_class.new(
              Accessibility::Rules::HeadingsStartAtH2Rule.id,
              wiki_page,
              "invalid_path",
              "Change it to Heading 2"
            )
          end

          it "returns an error with content" do
            result = html_fixer.preview_fix(element_only: false)

            expect(result).to eq(
              {
                status: :bad_request,
                json: {
                  content: nil,
                  path: nil,
                  error: "Element not found for path: invalid_path"
                },
              }
            )
          end
        end

        context "when fix succeeds" do
          let(:html_fixer) do
            described_class.new(
              Accessibility::Rules::HeadingsStartAtH2Rule.id,
              wiki_page,
              "./div/h1",
              "Change it to Heading 2"
            )
          end

          it "returns the full document with the fix applied" do
            result = html_fixer.preview_fix(element_only: false)

            expect(result).to eq(
              {
                status: :ok,
                json: {
                  content: "<div><h2>Page Title</h2></div>",
                  path: "./div/h2"
                },
              }
            )
          end
        end
      end

      context "with element_only: true (element only)" do
        context "when fix fails" do
          let(:html_fixer) do
            described_class.new(
              Accessibility::Rules::HeadingsStartAtH2Rule.id,
              wiki_page,
              "invalid_path",
              "Change it to Heading 2"
            )
          end

          it "returns an error with content" do
            result = html_fixer.preview_fix(element_only: true)

            expect(result).to eq(
              {
                status: :bad_request,
                json: {
                  content: nil,
                  path: nil,
                  error: "Element not found for path: invalid_path"
                },
              }
            )
          end
        end

        context "when fix succeeds" do
          let(:html_fixer) do
            described_class.new(
              Accessibility::Rules::HeadingsStartAtH2Rule.id,
              wiki_page,
              "./div/h1",
              "Change it to Heading 2"
            )
          end

          it "returns only the fixed element" do
            result = html_fixer.preview_fix(element_only: true)

            expect(result).to eq(
              {
                status: :ok,
                json: {
                  content: "<h2>Page Title</h2>",
                  path: "./div/h2"
                },
              }
            )
          end
        end
      end
    end

    context "with an assignment" do
      let(:assignment) { assignment_model(course:, description: "<div><h1>Assignment Title</h1></div>") }

      let(:html_fixer) do
        described_class.new(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          assignment,
          "./div/h1",
          "Change it to Heading 2"
        )
      end

      it "works with assignment descriptions" do
        result = html_fixer.preview_fix

        expect(result).to eq(
          {
            status: :ok,
            json: {
              content: "<div><h2>Assignment Title</h2></div>",
              path: "./div/h2"
            },
          }
        )
      end
    end

    context "with a discussion topic" do
      let(:discussion_topic) { discussion_topic_model(context: course, message: "<div><h1>Discussion Title</h1></div>") }

      let(:html_fixer) do
        described_class.new(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          discussion_topic,
          "./div/h1",
          "Change it to Heading 2"
        )
      end

      it "works with discussion topic messages" do
        result = html_fixer.preview_fix

        expect(result).to eq(
          {
            status: :ok,
            json: {
              content: "<div><h2>Discussion Title</h2></div>",
              path: "./div/h2"
            },
          }
        )
      end
    end

    context "with backwards compatibility for fix! return value" do
      let(:wiki_page) do
        wiki_page_model(
          course:,
          title: "Test Page",
          body: "<div><span id='test-element'>Original Content</span></div>"
        )
      end

      context "when rule returns array [element, preview_html]" do
        let(:mock_rule) { double("MockRule") }
        let(:mock_rule_registry) { { "test-array-rule" => mock_rule } }
        let(:html_fixer) do
          described_class.new(
            "test-array-rule",
            wiki_page,
            "./div/span[@id='test-element']",
            "fix_value"
          )
        end

        before do
          allow(Accessibility::Rule).to receive(:registry).and_return(mock_rule_registry)
          allow(mock_rule).to receive(:test).and_return(nil)
          allow(mock_rule).to receive(:fix!) do |elem, _value|
            elem.content = "Fixed Content"
            {
              changed: elem,
              content_preview: "<span id='test-element'>Fixed Content</span><p>Extra context</p>"
            }
          end
        end

        it "uses the preview_html from the array for element_only mode" do
          result = html_fixer.preview_fix(element_only: true)

          expect(result[:status]).to eq(:ok)
          expect(result[:json][:content]).to eq("<span id='test-element'>Fixed Content</span><p>Extra context</p>")
        end

        it "uses full document when element_only is false" do
          result = html_fixer.preview_fix(element_only: false)

          expect(result[:status]).to eq(:ok)
          expect(result[:json][:content]).to include("Fixed Content")
        end
      end

      context "when rule returns just the element (backwards compatible)" do
        let(:wiki_page) { wiki_page_model(course:, title: "Test Page", body: "<div><span id='old-element'>Old Text</span></div>") }
        let(:mock_rule) { double("MockRule") }
        let(:mock_rule_registry) { { "test-element-rule" => mock_rule } }
        let(:html_fixer) do
          described_class.new(
            "test-element-rule",
            wiki_page,
            "./div/span[@id='old-element']",
            "fix_value"
          )
        end

        before do
          allow(Accessibility::Rule).to receive(:registry).and_return(mock_rule_registry)
          allow(mock_rule).to receive(:test).and_return(nil)
          allow(mock_rule).to receive(:fix!) do |elem, _value|
            elem.content = "New Text"
            { changed: elem }
          end
        end

        it "still works with rules that return just the element" do
          result = html_fixer.preview_fix(element_only: true)

          expect(result[:status]).to eq(:ok)
          expect(result[:json][:content]).to eq("<span id=\"old-element\">New Text</span>")
        end
      end
    end
  end

  describe ".target_attribute" do
    context "with WikiPage" do
      let(:wiki_page) { wiki_page_model(course:) }

      it "returns :body" do
        expect(described_class.target_attribute(wiki_page)).to eq(:body)
      end
    end

    context "with Assignment" do
      let(:assignment) { assignment_model(course:) }

      it "returns :description" do
        expect(described_class.target_attribute(assignment)).to eq(:description)
      end
    end

    context "with DiscussionTopic" do
      let(:discussion_topic) { discussion_topic_model(context: course) }

      it "returns :message" do
        expect(described_class.target_attribute(discussion_topic)).to eq(:message)
      end
    end

    context "with unsupported resource type" do
      it "raises ArgumentError" do
        expect do
          described_class.target_attribute("invalid_resource")
        end.to raise_error(ArgumentError, "Unsupported resource type: String")
      end
    end
  end
end
