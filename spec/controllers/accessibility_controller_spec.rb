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
#

require "spec_helper"

describe AccessibilityController do
  render_views
  let(:mock_rule) do
    Class.new do
      def self.test(_elem) = true
      def self.id = "mock-rule"
      def self.message = "No issue"
      def self.why = "Just a mock"
      def self.form = []
    end
  end

  let(:rules) { [mock_rule] }

  let(:mock_pdf_rule) do # MUST be at this level
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
  let(:pdf_rules) { [mock_pdf_rule] }

  before do
    allow_any_instance_of(AccessibilityController).to receive(:require_context).and_return(true)
    allow_any_instance_of(AccessibilityController).to receive(:require_user).and_return(true)
    allow_any_instance_of(AccessibilityController).to receive(:setup_ruleset) do |controller|
      controller.instance_variable_set(:@ruleset, rules)
    end
    allow_any_instance_of(AccessibilityController).to receive(:allowed?).and_return(true)
  end

  describe "#create_accessibility_issues" do
    it "returns issues for pages" do
      page = double("WikiPage", id: 1, body: "<div>content</div>", title: "Page 1", published?: true, updated_at: Time.zone.now)
      # Set up explicit doubles for the chain
      wiki_pages = double("WikiPages")
      not_deleted = double("NotDeletedRelation")
      assignments = double("Assignments")
      active_assignments = double("ActiveAssignments")
      context_double = double("Context")
      attachments = double("Attachments")
      not_deleted_attachments = double("NotDeletedAttachmentsRelation")

      allow(wiki_pages).to receive_messages(not_deleted:)
      allow(not_deleted).to receive_messages(order: [page])
      allow(context_double).to receive_messages(wiki_pages:, assignments:, attachments:)
      allow(assignments).to receive_messages(active: active_assignments)
      allow(active_assignments).to receive_messages(order: [])
      allow(controller).to receive(:polymorphic_url).with([context_double, page]).and_return("https://fake.url")
      allow(attachments).to receive_messages(not_deleted: not_deleted_attachments)
      allow(not_deleted_attachments).to receive_messages(order: [])

      controller.instance_variable_set(:@context, context_double)

      result = controller.create_accessibility_issues(rules)
      expect(result[:pages][1][:title]).to eq("Page 1")
      expect(result[:pages][1][:published]).to be true
      expect(result[:assignments]).to eq({})
      expect(result[:last_checked]).to be_a(String)
    end

    it "returns issues for assignments" do
      assignment = double("Assignment", id: 2, description: "<div>desc</div>", title: "Assignment 1", published?: false, updated_at: Time.zone.now)
      # Set up explicit doubles for the chain
      wiki_pages = double("WikiPages")
      not_deleted = double("NotDeletedRelation")
      assignments = double("Assignments")
      active_assignments = double("ActiveAssignments")
      context_double = double("Context")
      attachments = double("Attachments")
      not_deleted_attachments = double("NotDeletedAttachmentsRelation")

      allow(wiki_pages).to receive_messages(not_deleted:)
      allow(not_deleted).to receive_messages(order: [])
      allow(attachments).to receive_messages(not_deleted: not_deleted_attachments)
      allow(not_deleted_attachments).to receive_messages(order: [])
      allow(context_double).to receive_messages(wiki_pages:, assignments:, attachments:)
      allow(assignments).to receive_messages(active: active_assignments)
      allow(active_assignments).to receive_messages(order: [assignment])
      allow(controller).to receive(:polymorphic_url).with([context_double, assignment]).and_return("https://fake.url")

      controller.instance_variable_set(:@context, context_double)

      result = controller.create_accessibility_issues(rules)
      expect(result[:pages]).to eq({})
      expect(result[:assignments][2][:title]).to eq("Assignment 1")
      expect(result[:assignments][2][:published]).to be false
      expect(result[:last_checked]).to be_a(String)
    end
  end

  it "returns issues for attachments" do
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

    context_double = double("Context")
    wiki_pages_collection = double("WikiPagesCollection")
    # These are the variables that were undefined in the original error
    not_deleted_wiki_pages_relation = double("NotDeletedWikiPagesRelation")
    assignments_collection = double("AssignmentsCollection")
    active_assignments_relation = double("ActiveAssignmentsRelation")
    attachments_collection = double("AttachmentsCollection")
    not_deleted_attachments_relation = double("NotDeletedAttachmentsRelation")

    # Set up the context chain
    allow(context_double).to receive_messages(
      wiki_pages: wiki_pages_collection,
      assignments: assignments_collection,
      attachments: attachments_collection
    )
    allow(wiki_pages_collection).to receive_messages(not_deleted: not_deleted_wiki_pages_relation)
    allow(assignments_collection).to receive_messages(active: active_assignments_relation)
    allow(attachments_collection).to receive_messages(not_deleted: not_deleted_attachments_relation)

    # Now use these defined doubles
    allow(not_deleted_wiki_pages_relation).to receive_messages(order: [])
    allow(active_assignments_relation).to receive_messages(order: [])
    allow(not_deleted_attachments_relation).to receive_messages(order: [attachment_pdf, attachment_other])

    # Set the @context for the controller instance
    controller.instance_variable_set(:@context, context_double)

    allow(controller).to receive(:course_files_url).with(context_double, preview: attachment_pdf.id).and_return("https://fake.url/files/3/preview")
    allow(controller).to receive(:course_files_url).with(context_double, preview: attachment_other.id).and_return("https://fake.url/files/4/preview")

    # Expect check_pdf_accessibility to be called with the attachment and the pdf_rules (which is [mock_pdf_rule class])
    # The return value should be a hash containing the :issues key, whose value comes from mock_pdf_rule.test
    expect(AccessibilityControllerHelper).to receive(:check_pdf_accessibility)
      .with(attachment_pdf, pdf_rules) # pdf_rules from let block
      .and_return({ issues: mock_pdf_rule.test(attachment_pdf) }) # call class method 'test'

    # Call the method under test, passing both sets of rules
    result = controller.create_accessibility_issues(rules, pdf_rules)

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

    expect(result[:last_checked]).to be_a(String)
  end

  describe "GET #issues" do
    before do
      allow_any_instance_of(AccessibilityController).to receive(:t).and_return("Accessibility")
      allow_any_instance_of(AccessibilityController).to receive(:add_crumb)
    end

    it "returns issues for pages" do
      allow_any_instance_of(AccessibilityController).to receive(:create_accessibility_issues).and_return({
                                                                                                           pages: { 1 => { title: "Page 1", published: true } },
                                                                                                           assignments: {},
                                                                                                           last_checked: "Apr 22, 2025"
                                                                                                         })
      get :issues, params: { course_id: 1 }, format: :json
      json = response.parsed_body
      expect(json["pages"]["1"]["title"]).to eq("Page 1")
      expect(json["pages"]["1"]["published"]).to be true
      expect(json["assignments"]).to eq({})
      expect(json["last_checked"]).to be_a(String)
    end

    it "returns issues for assignments" do
      allow_any_instance_of(AccessibilityController).to receive(:create_accessibility_issues).and_return({
                                                                                                           pages: {},
                                                                                                           assignments: { 2 => { title: "Assignment 1", published: false } },
                                                                                                           last_checked: "Apr 22, 2025"
                                                                                                         })
      get :issues, params: { course_id: 1 }, format: :json
      json = response.parsed_body
      expect(json["assignments"]["2"]["title"]).to eq("Assignment 1")
      expect(json["assignments"]["2"]["published"]).to be false
      expect(json["pages"]).to eq({})
      expect(json["last_checked"]).to be_a(String)
    end
  end

  describe "#show" do
    before do
      @course = Course.create!(name: "Test Course", id: 42)
      controller.instance_variable_set(:@context, @course)
    end

    it "renders the accessibility checker container if allowed" do
      get :show, params: { course_id: 42 }
      expect(response).to be_successful
      expect(response.body).to include("accessibility-checker-container")
    end

    it "returns nothing if not allowed" do
      allow_any_instance_of(AccessibilityController).to receive(:allowed?).and_return(false)
      get :show, params: { course_id: 42 }
      expect(response.body).not_to include("accessibility-checker-container")
    end
  end
end
