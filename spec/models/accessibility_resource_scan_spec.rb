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

    context "when no context is present" do
      it "returns nil" do
        expect(subject.context_url).to be_nil
      end
    end
  end
end
