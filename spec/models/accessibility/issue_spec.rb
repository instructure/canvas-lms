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
  let(:mock_rule) do
    Class.new do
      def self.test(_elem) = nil
      def self.id = "mock-rule"
      def self.message = "No issue"
      def self.why = "Just a mock"
      def self.form = []
    end
  end

  let(:mock_pdf_rule) do
    Class.new do
      def self.test(_elem)
        [{ id: "pdf-mock-issue", message: "PDF Mock issue found", why: "Just a mock PDF issue" }]
      end

      def self.id = "mock-pdf-rule-class"
      def self.message = "PDF Mock rule message"
      def self.why = "Because it's a mock PDF rule"
      def self.form = []
    end
  end

  let(:rules) { [mock_rule] }
  let(:pdf_rules) { [mock_pdf_rule] }

  describe "#generate" do
    let(:context_double) { double("Context") }

    before do
      allow_any_instance_of(described_class).to receive(:count_oversize_pages).and_return(0)
      allow_any_instance_of(described_class).to receive(:count_oversize_attachments).and_return(0)
      allow_any_instance_of(described_class).to receive(:exceeds_accessibility_scan_limit?).and_return(false)
    end

    it "returns issues for pages" do
      page = double("WikiPage", id: 1, body: "<div>content</div>", title: "Page 1", published?: true, updated_at: Time.zone.now)

      wiki_pages = double("WikiPages")
      not_deleted_wiki_pages = double("NotDeletedWikiPagesRelation")

      allow(context_double).to receive_messages(
        wiki_pages:,
        assignments: double("Assignments", active: double(order: [])),
        attachments: double("Attachments", not_deleted: double(order: []))
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
        attachments: double("Attachments", not_deleted: double(order: []))
      )
      allow(assignments).to receive(:active).and_return(active_assignments)
      allow(active_assignments).to receive(:order).and_return([assignment])

      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      result = described_class.new(context: context_double).generate

      expect(result[:assignments][2][:title]).to eq("Assignment 1")
      expect(result[:accessibility_scan_disabled]).to be false
    end

    # TODO: Disable PDF Accessibility Checks Until Post-InstCon
    it "returns issues for attachments", skip: "Not implemented yet" do
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
        attachments: attachments_collection
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
      allow_any_instance_of(described_class).to receive(:count_oversize_pages).and_return(10)
      allow_any_instance_of(described_class).to receive(:count_oversize_attachments).and_return(5)
      allow_any_instance_of(described_class).to receive(:exceeds_accessibility_scan_limit?).and_return(true)

      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments: double("Assignments", active: double(order: [])),
        attachments: double("Attachments", not_deleted: double(order: []))
      )

      result = described_class.new(context: context_double).generate
      expect(result[:accessibility_scan_disabled]).to be true
    end
  end

  describe "#update_content" do
    before do
      allow(Accessibility::Rule).to receive(:registry).and_return({ "mock-rule" => mock_rule })
    end

    it "returns bad request for empty input" do
      issue = described_class.new(context: double)
      response = issue.update_content(nil, nil, nil, nil, nil)

      expect(response[:status]).to eq(:bad_request)
      expect(response[:json][:error]).to include("Raw rule can't be blank")
    end

    it "returns unprocessable entity for invalid content type" do
      issue = described_class.new(context: double)
      response = issue.update_content("mock-rule", "InvalidType", nil, nil, nil)

      expect(response[:status]).to eq(:bad_request)
      expect(response[:json][:error]).to include("Content InvalidType with ID  not found")
    end

    it "returns bad request for invalid rule name" do
      context_double = double("Context")
      wiki_pages_double = double("WikiPages")

      allow(context_double).to receive(:wiki_pages).and_return(wiki_pages_double)
      allow(wiki_pages_double).to receive(:find_by).and_return(nil)

      issue = described_class.new(context: context_double)
      response = issue.update_content(
        "invalid-rule", "Page", 1, nil, nil
      )

      expect(response[:status]).to eq(:bad_request)
      expect(response[:json][:error]).to include("Raw rule is invalid")
    end

    it "updates a page successfully" do
      page = double("Page", id: 1, body: "<div>content</div>", save!: true)
      context_double = double("Context")
      wiki_pages_double = double("WikiPages")

      allow(context_double).to receive(:wiki_pages).and_return(wiki_pages_double)
      allow(wiki_pages_double).to receive(:find_by).and_return(page)

      allow(page).to receive(:body).and_return("<div>content</div>")
      allow(page).to receive(:body=)

      issue = described_class.new(context: context_double)
      allow_any_instance_of(Accessibility::Issue::HtmlFixer).to receive(:fix_content).and_return("<div>fixed content</div>")

      response = issue.update_content(
        "mock-rule", "Page", 1, "path", "value"
      )

      expect(response[:status]).to eq(:ok)
      expect(response[:json][:success]).to be true
      expect(page).to have_received(:body=).with("<div>fixed content</div>")
      expect(page).to have_received(:save!)
    end

    it "updates an assignment successfully" do
      assignment = double("Assignment", id: 2, description: "<div>desc</div>", save!: true)
      context_double = double("Context")
      assignments_double = double("Assignments")

      allow(context_double).to receive(:assignments).and_return(assignments_double)
      allow(assignments_double).to receive(:find_by).and_return(assignment)

      allow(assignment).to receive(:description).and_return("<div>desc</div>")
      allow(assignment).to receive(:description=)

      issue = described_class.new(context: context_double)
      allow_any_instance_of(Accessibility::Issue::HtmlFixer).to receive(:fix_content).and_return("<div>fixed description</div>")

      response = issue.update_content(
        "mock-rule", "Assignment", 2, "path", "value"
      )

      expect(response[:status]).to eq(:ok)
      expect(response[:json][:success]).to be true
      expect(assignment).to have_received(:description=).with("<div>fixed description</div>")
      expect(assignment).to have_received(:save!)
    end
  end

  describe "#update_preview" do
    before do
      allow(Accessibility::Rule).to receive(:registry).and_return({ "mock-rule" => mock_rule })
    end

    it "returns bad request for empty input" do
      issue = described_class.new(context: double)
      response = issue.update_preview(nil, nil, nil, nil, nil)

      expect(response[:status]).to eq(:bad_request)
      expect(response[:json][:error]).to include("Raw rule can't be blank")
    end

    it "returns unprocessable entity for invalid content type" do
      issue = described_class.new(context: double)
      response = issue.update_preview("mock-rule", "InvalidType", nil, nil, nil)

      expect(response[:status]).to eq(:bad_request)
      expect(response[:json][:error]).to include("Content InvalidType with ID  not found")
    end

    it "returns bad request for invalid rule name" do
      context_double = double("Context")
      wiki_pages_double = double("WikiPages")

      allow(context_double).to receive(:wiki_pages).and_return(wiki_pages_double)
      allow(wiki_pages_double).to receive(:find_by).and_return(nil)

      issue = described_class.new(context: context_double)
      response = issue.update_content(
        "invalid-rule", "Page", 1, nil, nil
      )

      expect(response[:status]).to eq(:bad_request)
      expect(response[:json][:error]).to include("Raw rule is invalid")
    end

    it "updates a page successfully" do
      page = double("Page", id: 1, body: "<div>content</div>", save!: true)
      context_double = double("Context")
      wiki_pages_double = double("WikiPages")

      allow(context_double).to receive(:wiki_pages).and_return(wiki_pages_double)
      allow(wiki_pages_double).to receive(:find_by).and_return(page)

      allow(page).to receive(:body).and_return("<div>content</div>")
      allow(page).to receive(:body=)

      issue = described_class.new(context: context_double)
      allow_any_instance_of(Accessibility::Issue::HtmlFixer).to receive(:fix_content).and_return("<div>fixed content</div>")

      response = issue.update_preview(
        "mock-rule", "Page", 1, "path", "value"
      )

      expect(response[:status]).to eq(:ok)
      expect(response[:json][:content]).to eq("<div>fixed content</div>")
    end

    it "updates an assignment successfully" do
      assignment = double("Assignment", id: 2, description: "<div>desc</div>", save!: true)
      context_double = double("Context")
      assignments_double = double("Assignments")

      allow(context_double).to receive(:assignments).and_return(assignments_double)
      allow(assignments_double).to receive(:find_by).and_return(assignment)

      allow(assignment).to receive(:description).and_return("<div>desc</div>")
      allow(assignment).to receive(:description=)

      issue = described_class.new(context: context_double)
      allow_any_instance_of(Accessibility::Issue::HtmlFixer).to receive(:fix_content).and_return("<div>fixed description</div>")

      response = issue.update_preview(
        "mock-rule", "Assignment", 2, "path", "value"
      )

      expect(response[:status]).to eq(:ok)
      expect(response[:json][:content]).to eq("<div>fixed description</div>")
    end
  end
end
