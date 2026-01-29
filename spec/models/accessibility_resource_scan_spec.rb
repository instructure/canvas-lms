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

describe AccessibilityResourceScan do
  subject { described_class.new }

  describe "defaults" do
    it "sets the default workflow_state to queued" do
      expect(subject.workflow_state).to eq "queued"
    end
  end

  describe "factories" do
    it "has a valid factory" do
      expect(accessibility_resource_scan_model).to be_valid
    end
  end

  describe "validations" do
    context "when course is missing" do
      before { subject.course = nil }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:course]).to include("can't be blank")
      end
    end

    describe "workflow_state" do
      context "when workflow_state is missing" do
        before { subject.workflow_state = nil }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:workflow_state]).to include("can't be blank")
        end
      end

      context "when workflow_state is not in the allowed list" do
        before { subject.workflow_state = "invalid_state" }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:workflow_state]).to include("is not included in the list")
        end
      end
    end

    describe "resource_workflow_state" do
      context "when resource_workflow_state is missing" do
        before { subject.resource_workflow_state = nil }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:resource_workflow_state]).to include("can't be blank")
        end
      end

      context "when resource_workflow_state is not in the allowed list" do
        before { subject.resource_workflow_state = "invalid_state" }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:resource_workflow_state]).to include("is not included in the list")
        end
      end
    end

    describe "issue_count" do
      context "when issue_count is missing" do
        before { subject.issue_count = nil }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:issue_count]).to include("can't be blank")
        end
      end
    end

    describe "wiki_page_id" do
      context "when the wiki_page_id is not unique" do
        let(:course) { course_model }
        let(:wiki_page) { wiki_page_model(course:) }

        before do
          accessibility_resource_scan_model(context: wiki_page)
          subject.wiki_page = wiki_page
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:wiki_page_id]).to include("has already been taken")
        end
      end
    end

    describe "assignment_id" do
      context "when the assignment_id is not unique" do
        let(:course) { course_model }
        let(:assignment) { assignment_model(course:) }

        before do
          accessibility_resource_scan_model(context: assignment)
          subject.assignment = assignment
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:assignment_id]).to include("has already been taken")
        end
      end
    end

    describe "attachment_id" do
      context "when the attachment_id is not unique" do
        let(:course) { course_model }
        let(:attachment) { attachment_model(course:) }

        before do
          accessibility_resource_scan_model(context: attachment)
          subject.attachment = attachment
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:attachment_id]).to include("has already been taken")
        end
      end
    end

    describe "discussion_topic_id" do
      context "when the discussion_topic_id is not unique" do
        let(:course) { course_model }
        let(:discussion_topic) { discussion_topic_model(course:) }

        before do
          accessibility_resource_scan_model(context: discussion_topic)
          subject.discussion_topic = discussion_topic
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:discussion_topic_id]).to include("has already been taken")
        end
      end
    end

    describe "announcement_id" do
      context "when the announcement_id is not unique" do
        let(:course) { course_model }
        let(:announcement) { announcement_model(course:) }

        before do
          accessibility_resource_scan_model(context: announcement)
          subject.announcement = announcement
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:announcement_id]).to include("has already been taken")
        end
      end
    end

    describe "is_syllabus_or_context" do
      let(:course) { course_model }
      let(:wiki_page) { wiki_page_model(course:) }

      context "when is_syllabus is true and context is present" do
        before do
          subject.course = course
          subject.is_syllabus = true
          subject.wiki_page = wiki_page
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include("is_syllabus and context must be mutually exclusive")
        end
      end

      context "when is_syllabus is true and context is nil" do
        before do
          subject.course = course
          subject.is_syllabus = true
        end

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "when is_syllabus is false and context is present" do
        before do
          subject.course = course
          subject.is_syllabus = false
          subject.wiki_page = wiki_page
        end

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "when is_syllabus is false and context is nil" do
        before do
          subject.course = course
          subject.is_syllabus = false
        end

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include("is_syllabus and context must be mutually exclusive")
        end
      end
    end
  end

  describe "#update_issue_count!" do
    let(:scan) { accessibility_resource_scan_model }

    context "when accessibility issues exist" do
      before do
        3.times { accessibility_issue_model(accessibility_resource_scan: scan, workflow_state: "active") }
        2.times { accessibility_issue_model(accessibility_resource_scan: scan, workflow_state: "resolved") }
      end

      it "updates issue_count with active issues count" do
        scan.update_issue_count!

        expect(scan.reload.issue_count).to eq 3
      end
    end

    context "when no accessibility issues exist" do
      it "updates issue_count to zero" do
        scan.update_issue_count!

        expect(scan.reload.issue_count).to eq 0
      end
    end
  end

  describe "#context_url" do
    let(:course_id) { 1 }

    before { allow(subject).to receive(:course_id).and_return(course_id) }

    context "when the context is a wiki_page" do
      let(:wiki_page) { wiki_page_model }

      it "returns the correct wiki_page URL" do
        subject.wiki_page = wiki_page
        expect(subject.context_url).to eq("/courses/#{subject.course_id}/pages/#{wiki_page.id}")
      end
    end

    context "when the context is an assignment" do
      let(:assignment) { assignment_model }

      it "returns the correct assignment URL" do
        subject.assignment = assignment
        expect(subject.context_url).to eq("/courses/#{subject.course_id}/assignments/#{assignment.id}")
      end
    end

    context "when the context is an attachment" do
      let(:attachment) { attachment_model }

      it "returns the correct attachment URL" do
        subject.attachment = attachment
        expect(subject.context_url).to eq("/courses/#{subject.course_id}/files?preview=#{attachment.id}")
      end
    end

    context "when the context is a discussion topic" do
      let(:discussion_topic) { discussion_topic_model }

      it "returns the correct discussion topic URL" do
        subject.discussion_topic = discussion_topic
        expect(subject.context_url).to eq("/courses/#{subject.course_id}/discussion_topics/#{discussion_topic.id}")
      end
    end

    context "when no context is present" do
      it "returns nil" do
        expect(subject.context_url).to be_nil
      end
    end
  end

  describe "#closed?" do
    let(:scan) { accessibility_resource_scan_model }

    context "when closed_at is present" do
      before { scan.update!(closed_at: Time.current) }

      it "returns true" do
        expect(scan.closed?).to be true
      end
    end

    context "when closed_at is nil" do
      before { scan.update!(closed_at: nil) }

      it "returns false" do
        expect(scan.closed?).to be false
      end
    end
  end

  describe "#open?" do
    let(:scan) { accessibility_resource_scan_model }

    context "when closed_at is nil" do
      before { scan.update!(closed_at: nil) }

      it "returns true" do
        expect(scan.open?).to be true
      end
    end

    context "when closed_at is present" do
      before { scan.update!(closed_at: Time.current) }

      it "returns false" do
        expect(scan.open?).to be false
      end
    end
  end

  describe "#bulk_close_issues!" do
    let(:scan) { accessibility_resource_scan_model }
    let(:user) { user_model }

    before do
      3.times { accessibility_issue_model(accessibility_resource_scan: scan, workflow_state: "active") }
      2.times { accessibility_issue_model(accessibility_resource_scan: scan, workflow_state: "resolved") }
    end

    context "when scan is open" do
      it "closes all active issues" do
        scan.bulk_close_issues!(user_id: user.id)

        expect(scan.accessibility_issues.where(workflow_state: "closed").count).to eq 3
        expect(scan.accessibility_issues.where(workflow_state: "resolved").count).to eq 2
      end

      it "sets updated_by_id on closed issues" do
        scan.bulk_close_issues!(user_id: user.id)

        scan.accessibility_issues.where(workflow_state: "closed").find_each do |issue|
          expect(issue.updated_by_id).to eq user.id
        end
      end

      it "updates updated_at on closed issues" do
        scan.bulk_close_issues!(user_id: user.id)

        scan.accessibility_issues.where(workflow_state: "closed").find_each do |issue|
          expect(issue.updated_at).to be_within(1.second).of(Time.current)
        end
      end

      it "sets closed_at on the scan" do
        scan.bulk_close_issues!(user_id: user.id)

        expect(scan.reload.closed_at).to be_within(1.second).of(Time.current)
      end

      it "sets issue_count to 0" do
        scan.bulk_close_issues!(user_id: user.id)

        expect(scan.reload.issue_count).to eq 0
      end

      it "performs all updates in a transaction" do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original

        scan.bulk_close_issues!(user_id: user.id)
      end

      it "does not trigger callbacks on issues (uses update_all)" do
        # This documents that we intentionally skip callbacks for performance
        # If callbacks are added that MUST run, this test will remind you to refactor
        expect_any_instance_of(AccessibilityIssue).not_to receive(:save)
        expect_any_instance_of(AccessibilityIssue).not_to receive(:update)

        scan.bulk_close_issues!(user_id: user.id)
      end
    end

    context "when scan is already closed" do
      before { scan.update!(closed_at: Time.current) }

      it "raises an error" do
        expect { scan.bulk_close_issues!(user_id: user.id) }.to raise_error("Resource is already closed")
      end
    end
  end
end
