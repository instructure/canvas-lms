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

describe "Accessibility::BulkCloseIssuesService Integration" do
  let(:course) { course_model }
  let(:user) { user_model }
  let(:wiki_page) { wiki_page_model(course:, body: "<p>Test content</p>") }

  # Create a scan with manually created issues (simpler than relying on actual scanner)
  let(:scan) do
    scan = AccessibilityResourceScan.create!(
      course:,
      context: wiki_page,
      workflow_state: "completed",
      resource_name: wiki_page.title,
      resource_workflow_state: "published",
      resource_updated_at: wiki_page.updated_at,
      issue_count: 3
    )

    # Create 3 active issues manually
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

    scan
  end

  describe "close then reopen with actual rescanning" do
    it "triggers ResourceScannerService and deletes old closed issues" do
      # Close the resource
      Accessibility::BulkCloseIssuesService.call(scan:, user_id: user.id, close: true)
      scan.reload

      old_issue_ids = scan.accessibility_issues.pluck(:id)
      expect(scan.closed?).to be true
      expect(scan.accessibility_issues.closed.count).to eq(3)
      expect(scan.accessibility_issues.active.count).to eq(0)

      # Reopen - this should call ResourceScannerService.call which queues a delayed job
      Accessibility::BulkCloseIssuesService.call(scan: scan.reload, user_id: user.id, close: false)

      # Process the delayed job
      run_jobs

      scan.reload

      # Old closed issues should be deleted by the scanner
      expect(AccessibilityIssue.where(id: old_issue_ids)).to be_empty

      # Scanner may or may not create new issues depending on content, but closed should be gone
      expect(scan.accessibility_issues.closed.count).to eq(0)
      expect(scan.open?).to be true
    end
  end

  describe "mixed issue states with real rescanning" do
    it "deletes only rescannable issues (active + closed) on reopen, preserving resolved/dismissed" do
      # Manually resolve one issue
      resolved_issue = scan.accessibility_issues.active.first
      resolved_issue.update!(workflow_state: "resolved")

      # Manually dismiss another issue
      dismissed_issue = scan.accessibility_issues.active.second
      dismissed_issue.update!(workflow_state: "dismissed")

      scan.reload
      expect(scan.accessibility_issues.active.count).to eq(1)

      # Close the remaining active issue
      Accessibility::BulkCloseIssuesService.call(scan:, user_id: user.id, close: true)
      scan.reload

      expect(scan.accessibility_issues.closed.count).to eq(1)
      expect(scan.accessibility_issues.resolved.count).to eq(1)
      expect(scan.accessibility_issues.dismissed.count).to eq(1)

      resolved_id = resolved_issue.id
      dismissed_id = dismissed_issue.id
      closed_ids = scan.accessibility_issues.closed.pluck(:id)

      # Reopen - trigger real re-scan
      Accessibility::BulkCloseIssuesService.call(scan: scan.reload, user_id: user.id, close: false)

      # Process the delayed job
      run_jobs

      scan.reload

      # Resolved and dismissed should still exist (not rescannable)
      expect(AccessibilityIssue.exists?(resolved_id)).to be true
      expect(AccessibilityIssue.exists?(dismissed_id)).to be true

      # Closed issues should be gone (deleted by rescan)
      closed_ids.each do |closed_id|
        expect(AccessibilityIssue.exists?(closed_id)).to be false
      end

      expect(scan.accessibility_issues.closed.count).to eq(0)
    end
  end
end
