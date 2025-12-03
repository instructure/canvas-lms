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

describe Accessibility::Issue do
  describe "#generate" do
    let(:context_double) { double("Context") }

    it "returns issues for pages" do
      page = double("WikiPage", id: 1, body: "<div>content</div>", title: "Page 1", published?: true, updated_at: Time.zone.now)

      wiki_pages = double("WikiPages")
      not_deleted_wiki_pages = double("NotDeletedWikiPagesRelation")

      allow(context_double).to receive_messages(
        wiki_pages:,
        assignments: double("Assignments", active: double(order: [])),
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: false
      )
      allow(wiki_pages).to receive(:not_deleted).and_return(not_deleted_wiki_pages)
      allow(not_deleted_wiki_pages).to receive(:order).and_return([page])

      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      result = described_class.new(context: context_double).generate

      expect(result[:pages][1][:title]).to eq("Page 1")
      expect(result[:accessibility_scan_disabled]).to be false
    end

    it "returns issues for assignments" do
      assignment = double("Assignment", id: 2, description: "<div>desc</div>", title: "Assignment 1", published?: false, updated_at: Time.zone.now)

      assignments = double("Assignments")
      active_assignments = double("ActiveAssignments")

      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments:,
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: false
      )
      allow(assignments).to receive(:active).and_return(active_assignments)
      allow(active_assignments).to receive(:order).and_return([assignment])

      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      result = described_class.new(context: context_double).generate

      expect(result[:assignments][2][:title]).to eq("Assignment 1")
      expect(result[:accessibility_scan_disabled]).to be false
    end

    # TODO: Disable PDF Accessibility Checks Until Post-InstCon
    it "returns issues for attachments", skip: "LMA-181 2025-06-11" do
      attachment_pdf = double("AttachmentPDF",
                              id: 3,
                              title: "Document.pdf",
                              content_type: "application/pdf",
                              published?: true,
                              updated_at: Time.zone.now)
      attachment_other = double("AttachmentOther",
                                id: 4,
                                title: "Image.png",
                                content_type: "image/png",
                                published?: false,
                                updated_at: Time.zone.now)

      attachments_collection = double("AttachmentsCollection")
      not_deleted_attachments_relation = double("NotDeletedAttachmentsRelation")

      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments: double("Assignments", active: double(order: [])),
        attachments: attachments_collection,
        exceeds_accessibility_scan_limit?: false
      )
      allow(attachments_collection).to receive(:not_deleted).and_return(not_deleted_attachments_relation)
      allow(not_deleted_attachments_relation).to receive(:order).and_return([attachment_pdf, attachment_other])

      allow(Rails.application.routes.url_helpers).to receive(:course_files_url) do |_, options|
        case options[:preview]
        when 3 then "https://fake.url/files/3/preview"
        when 4 then "https://fake.url/files/4/preview"
        else "https://fake.url/files/unknown/preview"
        end
      end

      issues = described_class.new(context: context_double)

      expect(issues).to receive(:check_pdf_accessibility)
        .with(attachment_pdf)
        .and_return({ issues: mock_pdf_rule.test(attachment_pdf) })

      result = issues.generate

      expect(result[:pages]).to eq({})
      expect(result[:assignments]).to eq({})

      expect(result[:attachments][3][:title]).to eq("Document.pdf")
      expect(result[:attachments][3][:content_type]).to eq("application/pdf")
      expect(result[:attachments][3][:published]).to be true
      expect(result[:attachments][3][:url]).to eq("https://fake.url/files/3/preview")
      expect(result[:attachments][3][:issues].first[:id]).to eq("pdf-mock-issue")
      expect(result[:attachments][3][:issues].first[:message]).to eq("PDF Mock issue found")

      expect(result[:attachments][4][:title]).to eq("Image.png")
      expect(result[:attachments][4][:content_type]).to eq("image/png")
      expect(result[:attachments][4][:published]).to be false
      expect(result[:attachments][4][:url]).to eq("https://fake.url/files/4/preview")
      expect(result[:attachments][4][:issues]).to be_nil

      expect(result[:accessibility_scan_disabled]).to be false
    end

    it "returns nils if size limits exceeded" do
      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments: double("Assignments", active: double(order: [])),
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: true
      )

      result = described_class.new(context: context_double).generate
      expect(result[:accessibility_scan_disabled]).to be true
    end
  end

  describe "#update_content" do
    let(:course) { course_model }
    let(:resource) { wiki_page_model(course:, title: "Test Page", body: "<div><h1>Page Title</h1></div>") }

    it "raises error for invalid resource type" do
      issue = described_class.new(context: course)
      expect do
        issue.update_content(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "InvalidType",
          nil,
          nil,
          nil
        )
      end.to raise_error(ArgumentError)
    end

    it "raises error for invalid resource" do
      issue = described_class.new(context: course)
      expect do
        issue.update_content(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "Page",
          nil,
          nil,
          nil
        )
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns an error message for fix issues" do
      issue = described_class.new(context: course)
      response = issue.update_content(
        Accessibility::Rules::HeadingsStartAtH2Rule.id,
        "Page",
        resource.id,
        "./invalid_path",
        "Change it to Heading 2"
      )
      expect(response).to eq(
        {
          json: { error: "Element not found for path: ./invalid_path" },
          status: :bad_request,
        }
      )
    end

    context "with a wiki page" do
      it "updates the resource successfully" do
        issue = described_class.new(context: course)
        response = issue.update_content(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "Page",
          resource.id,
          ".//h1",
          "Change it to Heading 2"
        )
        expect(response).to eq(
          {
            json: { success: true },
            status: :ok
          }
        )
        expect(resource.reload.body).to eq "<div><h2>Page Title</h2></div>"
      end
    end

    context "with an assignment" do
      let(:resource) { assignment_model(course:, description: "<div><h1>Assignment Title</h1></div>") }

      it "updates an assignment successfully" do
        issue = described_class.new(context: course)
        response = issue.update_content(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "Assignment",
          resource.id,
          ".//h1",
          "Change it to Heading 2"
        )
        expect(response).to eq(
          {
            json: { success: true },
            status: :ok
          }
        )
        expect(resource.reload.description).to eq "<div><h2>Assignment Title</h2></div>"
      end
    end
  end

  describe "#update_preview" do
    let(:course) { course_model }
    let(:resource) { wiki_page_model(course:, title: "Test Page", body: "<div><h1>Page Title</h1></div>") }

    it "raises error for invalid resource type" do
      issue = described_class.new(context: course)
      expect do
        issue.update_preview(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "InvalidType",
          nil,
          nil,
          nil
        )
      end.to raise_error(ArgumentError)
    end

    it "raises error for invalid resource" do
      issue = described_class.new(context: course)
      expect do
        issue.update_preview(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "Page",
          nil,
          nil,
          nil
        )
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "with a wiki page" do
      it "previews the resource successfully" do
        issue = described_class.new(context: course)
        response = issue.update_preview(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "Page",
          resource.id,
          ".//h1",
          "Change it to Heading 2"
        )
        expect(response).to eq(
          {
            json: { content: "<h2>Page Title</h2>", path: "./div/h2" },
            status: :ok
          }
        )
      end
    end

    context "with an assignment" do
      let(:resource) { assignment_model(course:, description: "<div><h1>Assignment Title</h1></div>") }

      it "previews the resource successfully" do
        issue = described_class.new(context: course)
        response = issue.update_preview(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "Assignment",
          resource.id,
          ".//h1",
          "Change it to Heading 2"
        )
        expect(response).to eq(
          {
            json: { content: "<h2>Assignment Title</h2>", path: "./div/h2" },
            status: :ok
          }
        )
      end
    end
  end
end
