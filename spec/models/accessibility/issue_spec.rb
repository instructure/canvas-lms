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

      assignments = double("Assignments")
      active_assignments = double("ActiveAssignments")
      not_excluded_assignments = double("NotExcludedAssignments")

      discussion_topics = double("DiscussionTopics")
      announcements = double("Announcements")

      allow(context_double).to receive_messages(
        wiki_pages:,
        assignments:,
        discussion_topics:,
        announcements:,
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: false
      )
      allow(wiki_pages).to receive(:not_deleted).and_return(not_deleted_wiki_pages)
      allow(not_deleted_wiki_pages).to receive(:order).and_return([page])

      allow(assignments).to receive(:active).and_return(active_assignments)
      allow(active_assignments).to receive(:not_excluded_from_accessibility_scan).and_return(not_excluded_assignments)
      allow(not_excluded_assignments).to receive(:order).and_return([])

      allow(discussion_topics).to receive(:scannable).and_return([])
      allow(announcements).to receive(:active).and_return([])

      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      result = described_class.new(context: context_double).generate

      expect(result[:pages][1][:title]).to eq("Page 1")
      expect(result[:accessibility_scan_disabled]).to be false
    end

    it "returns issues for assignments" do
      assignment = double("Assignment", id: 2, description: "<div>desc</div>", title: "Assignment 1", published?: false, updated_at: Time.zone.now)

      assignments = double("Assignments")
      active_assignments = double("ActiveAssignments")
      not_excluded_assignments = double("NotExcludedAssignments")

      discussion_topics = double("DiscussionTopics")
      announcements = double("Announcements")

      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments:,
        discussion_topics:,
        announcements:,
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: false
      )
      allow(assignments).to receive(:active).and_return(active_assignments)
      allow(active_assignments).to receive(:not_excluded_from_accessibility_scan).and_return(not_excluded_assignments)
      allow(not_excluded_assignments).to receive(:order).and_return([assignment])

      allow(discussion_topics).to receive(:scannable).and_return([])
      allow(announcements).to receive(:active).and_return([])

      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      result = described_class.new(context: context_double).generate

      expect(result[:assignments][2][:title]).to eq("Assignment 1")
      expect(result[:accessibility_scan_disabled]).to be false
    end

    it "returns issues for discussion topics" do
      discussion_topic = double("DiscussionTopic", id: 3, message: "<div>message</div>", title: "Discussion 1", published?: true, updated_at: Time.zone.now)

      discussion_topics = double("DiscussionTopics")
      announcements = double("Announcements")

      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments: double("Assignments", active: double(not_excluded_from_accessibility_scan: double(order: []))),
        discussion_topics:,
        announcements:,
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: false
      )

      allow(discussion_topics).to receive(:scannable).and_return([discussion_topic])
      allow(announcements).to receive(:active).and_return([])

      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      result = described_class.new(context: context_double).generate

      expect(result[:discussion_topics][3][:title]).to eq("Discussion 1")
      expect(result[:accessibility_scan_disabled]).to be false
    end

    it "returns issues for announcements" do
      announcement = double("Announcement", id: 4, message: "<div>announcement message</div>", title: "Announcement 1", published?: true, updated_at: Time.zone.now)

      announcements = double("Announcements")

      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments: double("Assignments", active: double(not_excluded_from_accessibility_scan: double(order: []))),
        discussion_topics: double("DiscussionTopics", scannable: []),
        announcements:,
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: false
      )

      allow(announcements).to receive(:active).and_return([announcement])

      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      result = described_class.new(context: context_double).generate

      expect(result[:announcements][4][:title]).to eq("Announcement 1")
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

      discussion_topics = double("DiscussionTopics")
      announcements = double("Announcements")

      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments: double("Assignments", active: double(not_excluded_from_accessibility_scan: double(order: []))),
        discussion_topics:,
        announcements:,
        attachments: attachments_collection,
        exceeds_accessibility_scan_limit?: false
      )
      allow(attachments_collection).to receive(:not_deleted).and_return(not_deleted_attachments_relation)
      allow(not_deleted_attachments_relation).to receive(:order).and_return([attachment_pdf, attachment_other])

      allow(discussion_topics).to receive(:scannable).and_return([])
      allow(announcements).to receive(:active).and_return([])

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
      assignments = double("Assignments")
      active_assignments = double("ActiveAssignments")
      not_excluded_assignments = double("NotExcludedAssignments")

      discussion_topics = double("DiscussionTopics")
      announcements = double("Announcements")

      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments:,
        discussion_topics:,
        announcements:,
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: true
      )

      allow(assignments).to receive(:active).and_return(active_assignments)
      allow(active_assignments).to receive(:not_excluded_from_accessibility_scan).and_return(not_excluded_assignments)
      allow(not_excluded_assignments).to receive(:order).and_return([])

      allow(discussion_topics).to receive(:scannable).and_return([])
      allow(announcements).to receive(:active).and_return([])

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
        "Change heading level to Heading 2"
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
          "Change heading level to Heading 2"
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
          "Change heading level to Heading 2"
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

    context "with a discussion topic" do
      let(:resource) { discussion_topic_model(context: course, message: "<div><h1>Discussion Title</h1></div>") }

      it "updates a discussion topic successfully" do
        issue = described_class.new(context: course)
        response = issue.update_content(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "DiscussionTopic",
          resource.id,
          ".//h1",
          "Change heading level to Heading 2"
        )
        expect(response).to eq(
          {
            json: { success: true },
            status: :ok
          }
        )
        expect(resource.reload.message).to eq "<div><h2>Discussion Title</h2></div>"
      end
    end

    context "with an announcement" do
      let(:resource) { announcement_model(context: course, message: "<div><h1>Announcement Title</h1></div>") }

      it "updates an announcement successfully" do
        issue = described_class.new(context: course)
        response = issue.update_content(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "Announcement",
          resource.id,
          ".//h1",
          "Change heading level to Heading 2"
        )
        expect(response).to eq(
          {
            json: { success: true },
            status: :ok
          }
        )
        expect(resource.reload.message).to eq "<div><h2>Announcement Title</h2></div>"
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
          "Change heading level to Heading 2"
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
          "Change heading level to Heading 2"
        )
        expect(response).to eq(
          {
            json: { content: "<h2>Assignment Title</h2>", path: "./div/h2" },
            status: :ok
          }
        )
      end
    end

    context "with a discussion topic" do
      let(:resource) { discussion_topic_model(context: course, message: "<div><h1>Discussion Title</h1></div>") }

      it "previews the resource successfully" do
        issue = described_class.new(context: course)
        response = issue.update_preview(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "DiscussionTopic",
          resource.id,
          ".//h1",
          "Change heading level to Heading 2"
        )
        expect(response).to eq(
          {
            json: { content: "<h2>Discussion Title</h2>", path: "./div/h2" },
            status: :ok
          }
        )
      end
    end

    context "with an announcement" do
      let(:resource) { announcement_model(context: course, message: "<div><h1>Announcement Title</h1></div>") }

      it "previews the resource successfully" do
        issue = described_class.new(context: course)
        response = issue.update_preview(
          Accessibility::Rules::HeadingsStartAtH2Rule.id,
          "Announcement",
          resource.id,
          ".//h1",
          "Change heading level to Heading 2"
        )
        expect(response).to eq(
          {
            json: { content: "<h2>Announcement Title</h2>", path: "./div/h2" },
            status: :ok
          }
        )
      end
    end
  end

  describe "#search" do
    let(:course) { course_model }
    let(:context_double) { double("Context") }

    before do
      allow(context_double).to receive_messages(
        wiki_pages: double("WikiPages", not_deleted: double(order: [])),
        assignments: double("Assignments", active: double(not_excluded_from_accessibility_scan: double(order: []))),
        discussion_topics: double("DiscussionTopics", scannable: []),
        announcements: double("Announcements"),
        attachments: double("Attachments", not_deleted: double(order: [])),
        exceeds_accessibility_scan_limit?: false
      )
    end

    it "filters announcements by query" do
      announcement1 = double("Announcement",
                             id: 1,
                             message: "<p>Apple announcement content</p>",
                             title: "Apple Announcement",
                             published?: true,
                             updated_at: Time.zone.now)
      announcement2 = double("Announcement",
                             id: 2,
                             message: "<p>Banana announcement content</p>",
                             title: "Banana Announcement",
                             published?: true,
                             updated_at: Time.zone.now)

      allow(context_double.announcements).to receive(:active).and_return([announcement1, announcement2])
      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      issue = described_class.new(context: context_double)
      result = issue.search("Apple")

      filtered_announcements = result[:announcements].select { |ann| ann[:title]&.include?("Apple") }
      expect(filtered_announcements.count).to be >= 1
    end

    it "returns all announcements when query is blank" do
      announcement1 = double("Announcement",
                             id: 1,
                             message: "<p>First announcement</p>",
                             title: "First Announcement",
                             published?: true,
                             updated_at: Time.zone.now)
      announcement2 = double("Announcement",
                             id: 2,
                             message: "<p>Second announcement</p>",
                             title: "Second Announcement",
                             published?: true,
                             updated_at: Time.zone.now)

      allow(context_double.announcements).to receive(:active).and_return([announcement1, announcement2])
      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      issue = described_class.new(context: context_double)
      result = issue.search("")

      expect(result[:announcements].count).to eq(2)
    end

    it "filters pages, assignments, and discussion topics along with announcements" do
      page = double("WikiPage",
                    id: 1,
                    body: "<div>Apple page content</div>",
                    title: "Apple Page",
                    published?: true,
                    updated_at: Time.zone.now)
      announcement = double("Announcement",
                            id: 2,
                            message: "<p>Banana announcement</p>",
                            title: "Banana Announcement",
                            published?: true,
                            updated_at: Time.zone.now)

      allow(context_double.wiki_pages.not_deleted).to receive(:order).and_return([page])
      allow(context_double.announcements).to receive(:active).and_return([announcement])
      allow(Rails.application.routes.url_helpers).to receive(:polymorphic_url).and_return("https://fake.url")

      issue = described_class.new(context: context_double)
      result = issue.search("Apple")

      expect(result[:pages].any? { |p| p[:title]&.include?("Apple") }).to be true
      expect(result[:announcements].any? { |a| a[:title]&.include?("Apple") }).to be false
    end
  end

  describe ".find_resource" do
    let(:course) { course_model }

    context "with Page type" do
      let(:page) { wiki_page_model(course:, title: "Test Page") }

      it "finds the page by id" do
        result = described_class.find_resource(course, "Page", page.id)
        expect(result).to eq(page)
      end

      it "raises RecordNotFound for invalid id" do
        expect do
          described_class.find_resource(course, "Page", 99)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with Assignment type" do
      let(:assignment) { assignment_model(course:, title: "Test Assignment") }

      it "finds the assignment by id" do
        result = described_class.find_resource(course, "Assignment", assignment.id)
        expect(result).to eq(assignment)
      end

      it "raises RecordNotFound for invalid id" do
        expect do
          described_class.find_resource(course, "Assignment", 99)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with DiscussionTopic type" do
      let(:discussion_topic) { discussion_topic_model(context: course, title: "Test Discussion") }

      it "finds the discussion topic by id" do
        result = described_class.find_resource(course, "DiscussionTopic", discussion_topic.id)
        expect(result).to eq(discussion_topic)
      end

      it "raises RecordNotFound for invalid id" do
        expect do
          described_class.find_resource(course, "DiscussionTopic", 99)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with Announcement type" do
      let(:announcement) { announcement_model(context: course, title: "Test Announcement") }

      it "finds the announcement by id" do
        result = described_class.find_resource(course, "Announcement", announcement.id)
        expect(result).to eq(announcement)
      end

      it "raises RecordNotFound for invalid id" do
        expect do
          described_class.find_resource(course, "Announcement", 99)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with unsupported type" do
      it "raises ArgumentError" do
        expect do
          described_class.find_resource(course, "UnsupportedType", 1)
        end.to raise_error(ArgumentError, "Unsupported resource type: UnsupportedType")
      end
    end
  end
end
