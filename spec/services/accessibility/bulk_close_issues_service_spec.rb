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

describe Accessibility::BulkCloseIssuesService do
  let(:course) { course_model }
  let(:user) { user_model }
  let(:wiki_page) { wiki_page_model(course:, body: "<img src='test.jpg'><img src='test2.jpg'><img src='test3.jpg'>") }
  let(:scan) do
    AccessibilityResourceScan.create!(
      course:,
      context: wiki_page,
      workflow_state: "completed",
      resource_name: wiki_page.title,
      resource_workflow_state: "published",
      resource_updated_at: wiki_page.updated_at,
      issue_count: 3
    )
  end

  before do
    # Create 3 active issues
    3.times do |i|
      scan.accessibility_issues.create!(
        course:,
        context: wiki_page,
        workflow_state: "active",
        rule_type: "img-alt",
        node_path: "//img[#{i + 1}]",
        metadata: { element: "img" }
      )
    end
  end

  describe "#call with close: true" do
    subject { described_class.call(scan:, user_id: user.id, close: true) }

    context "when resource is open" do
      it "marks all active issues as closed" do
        expect { subject }.to change {
          scan.accessibility_issues.reload.all?(&:closed?)
        }.from(false).to(true)
      end

      it "sets updated_by_id on all issues" do
        subject
        expect(scan.accessibility_issues.reload.all? { |i| i.updated_by_id == user.id }).to be true
      end

      it "updates the updated_at timestamp on issues" do
        Timecop.freeze do
          subject
          expect(scan.accessibility_issues.reload.all? { |i| i.updated_at == Time.current }).to be true
        end
      end

      it "sets closed_at on scan" do
        Timecop.freeze do
          expect { subject }.to change { scan.reload.closed_at }.from(nil).to(Time.current)
        end
      end

      it "sets issue_count to 0" do
        expect { subject }.to change { scan.reload.issue_count }.from(3).to(0)
      end

      it "does not affect resolved issues" do
        resolved_issue = scan.accessibility_issues.create!(
          course:,
          context: wiki_page,
          workflow_state: "resolved",
          rule_type: "img-alt",
          node_path: "//img[4]",
          metadata: { element: "img" }
        )

        subject

        expect(resolved_issue.reload.workflow_state).to eq("resolved")
      end

      it "does not affect dismissed issues" do
        dismissed_issue = scan.accessibility_issues.create!(
          course:,
          context: wiki_page,
          workflow_state: "dismissed",
          rule_type: "img-alt",
          node_path: "//img[5]",
          metadata: { element: "img" }
        )

        subject

        expect(dismissed_issue.reload.workflow_state).to eq("dismissed")
      end

      it "uses a transaction" do
        allow(ActiveRecord::Base).to receive(:transaction).and_call_original
        subject
        expect(ActiveRecord::Base).to have_received(:transaction)
      end
    end

    context "when resource is already closed" do
      before do
        scan.update!(closed_at: 1.hour.ago)
      end

      it "raises an error" do
        expect { subject }.to raise_error("Resource is already closed")
      end

      it "does not modify the scan" do
        original_closed_at = scan.closed_at
        expect { subject }.to raise_error("Resource is already closed")
        expect(scan.reload.closed_at).to eq(original_closed_at)
      end

      it "does not modify issues" do
        expect { subject }.to raise_error("Resource is already closed")
        expect(scan.accessibility_issues.active.count).to eq(3)
      end
    end

    context "when there are no active issues" do
      before do
        scan.accessibility_issues.active.update_all(workflow_state: "resolved")
        scan.update!(issue_count: 0)
      end

      it "still sets closed_at on scan" do
        Timecop.freeze do
          expect { subject }.to change { scan.reload.closed_at }.from(nil).to(Time.current)
        end
      end

      it "keeps issue_count at 0" do
        subject
        expect(scan.reload.issue_count).to eq(0)
      end
    end
  end

  describe "#call with close: false" do
    subject { described_class.call(scan: scan.reload, user_id: user.id, close: false) }

    before do
      # First close the resource
      described_class.call(scan:, user_id: user.id, close: true)
      scan.reload
    end

    context "when resource is closed" do
      it "resets closed_at to nil" do
        expect { subject }.to change { scan.reload.closed_at }.from(be_present).to(nil)
      end

      it "calls ResourceScannerService" do
        expect(Accessibility::ResourceScannerService).to receive(:call).with(resource: wiki_page)
        subject
      end
    end

    context "when resource is already open" do
      before do
        scan.update!(closed_at: nil)
      end

      it "raises an error" do
        expect { subject }.to raise_error("Resource is not closed")
      end

      it "does not call ResourceScannerService" do
        expect(Accessibility::ResourceScannerService).not_to receive(:call)
        expect { subject }.to raise_error("Resource is not closed")
      end
    end
  end

  describe "workflow scenarios" do
    context "close then reopen workflow" do
      it "correctly transitions through states" do
        # Initial state: open with 3 active issues
        expect(scan.open?).to be true
        expect(scan.issue_count).to eq(3)
        expect(scan.accessibility_issues.active.count).to eq(3)

        # Close the resource
        described_class.call(scan:, user_id: user.id, close: true)
        scan.reload

        expect(scan.closed?).to be true
        expect(scan.issue_count).to eq(0)
        expect(scan.accessibility_issues.closed.count).to eq(3)
        expect(scan.accessibility_issues.active.count).to eq(0)

        # Reopen the resource
        allow_any_instance_of(Accessibility::ResourceScannerService)
          .to receive(:scan_resource_for_issues)
          .and_return({ issues: [] })

        described_class.call(scan: scan.reload, user_id: user.id, close: false)
        scan.reload

        expect(scan.open?).to be true
        expect(scan.closed_at).to be_nil
      end
    end

    context "when multiple users interact with the resource" do
      let(:user2) { user_model }

      it "tracks the correct user who closed the resource" do
        described_class.call(scan:, user_id: user.id, close: true)
        scan.reload

        expect(scan.accessibility_issues.all? { |i| i.updated_by_id == user.id }).to be true
      end

      it "allows a different user to reopen" do
        described_class.call(scan:, user_id: user.id, close: true)
        scan.reload

        allow_any_instance_of(Accessibility::ResourceScannerService)
          .to receive(:scan_resource_for_issues)
          .and_return({ issues: [] })

        expect do
          described_class.call(scan: scan.reload, user_id: user2.id, close: false)
        end.not_to raise_error
      end
    end

    context "when content has mixed issue states" do
      before do
        # Add a resolved issue
        scan.accessibility_issues.create!(
          course:,
          context: wiki_page,
          workflow_state: "resolved",
          rule_type: "img-alt",
          node_path: "//img[4]",
          metadata: { element: "img" }
        )

        # Add a dismissed issue
        scan.accessibility_issues.create!(
          course:,
          context: wiki_page,
          workflow_state: "dismissed",
          rule_type: "img-alt",
          node_path: "//img[5]",
          metadata: { element: "img" }
        )
      end

      it "only closes active issues" do
        described_class.call(scan:, user_id: user.id, close: true)
        scan.reload

        expect(scan.accessibility_issues.closed.count).to eq(3)
        expect(scan.accessibility_issues.resolved.count).to eq(1)
        expect(scan.accessibility_issues.dismissed.count).to eq(1)
      end
    end
  end
end
