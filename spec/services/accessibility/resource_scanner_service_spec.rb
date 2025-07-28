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

describe Accessibility::ResourceScannerService do
  subject { described_class.new(resource: wiki_page) }

  let(:course) { course_model }
  let(:wiki_page) { wiki_page_model(course:) }
  let(:assignment) { assignment_model(course:) }
  let(:attachment) { attachment_model(course:, content_type: "application/pdf") }

  describe "#call" do
    let(:delay_mock) { double("delay") }

    before do
      allow(subject).to receive(:delay).and_return(delay_mock)
      allow(delay_mock).to receive(:scan_resource)
    end

    context "when the scan is not present" do
      it "creates a scan for the resource" do
        described_class.call(resource: wiki_page)

        scan = AccessibilityResourceScan.for_context(wiki_page).first
        expect(scan).to be_present
      end

      it "enqueues a delayed job for scanning the resource" do
        expect(subject).to receive(:delay)
          .with(singleton: "accessibility_scan_resource_#{wiki_page.global_id}")
          .and_return(delay_mock)
        expect(delay_mock).to receive(:scan_resource)

        subject.call
      end
    end

    context "when the scan is queued" do
      before do
        accessibility_resource_scan_model(course:, wiki_page:, workflow_state: "queued")
      end

      it "does not enqueue another scan" do
        expect(delay_mock).not_to receive(:scan_resource)

        subject.call
      end
    end

    context "when the scan is completed" do
      let!(:scan) { accessibility_resource_scan_model(course:, wiki_page:, workflow_state: "completed") }

      it "re-enqueues the scan" do
        described_class.call(resource: wiki_page)

        scan.reload
        expect(scan.workflow_state).to eq("queued")
      end

      it "enqueues a delayed job for scanning the resource" do
        expect(subject).to receive(:delay)
          .with(singleton: "accessibility_scan_resource_#{wiki_page.global_id}")
          .and_return(delay_mock)
        expect(delay_mock).to receive(:scan_resource)

        subject.call
      end
    end
  end

  describe "#scan_resource" do
    let!(:scan) { accessibility_resource_scan_model(course:, wiki_page:, workflow_state: "queued") }

    it "updates the scan to in progress" do
      expect_any_instance_of(AccessibilityResourceScan).to receive(:in_progress!)

      subject.scan_resource(scan:)
    end

    context "when the scan completes successfully" do
      context "when there are existing AccessibilityIssue records" do
        let(:existing_issue) do
          accessibility_issue_model(course:, wiki_page:)
        end

        it "deletes the existing records" do
          subject.scan_resource(scan:)

          expect(AccessibilityIssue.for_context(wiki_page)).not_to exist
        end
      end

      context "when issues were found" do
        before do
          html_with_issues = <<-HTML
            <div>
              <h1>H1 Title</h1>
              <h2>H2 Title</h2>
              <h4>H4 Title</h4>
            </div>
          HTML
          wiki_page.update!(body: html_with_issues)
        end

        it "creates the proper number of AccessibilityIssue records" do
          subject.scan_resource(scan:)

          issues = AccessibilityIssue.for_context(wiki_page)
          expect(AccessibilityIssue.for_context(wiki_page).count).to be(2)
          expect(issues.first.rule_type).to eq(Accessibility::Rules::HeadingsSequenceRule.id)
          expect(issues.second.rule_type).to eq(Accessibility::Rules::HeadingsStartAtH2Rule.id)
        end

        it "updates the scan with the issue count" do
          subject.scan_resource(scan:)

          expect(scan.reload.issue_count).to eq(2)
        end

        it "connects the scan to the issue" do
          subject.scan_resource(scan:)

          issue = AccessibilityIssue.for_context(wiki_page).first
          expect(issue.accessibility_resource_scan).to eq(scan)
        end
      end

      it "updates the scan to completed" do
        subject.scan_resource(scan:)

        expect(scan.reload.workflow_state).to eq("completed")
      end
    end

    context "when the scan fails" do
      before do
        allow_any_instance_of(described_class).to receive(:scan_resource_for_issues).and_raise(StandardError, "Failure")
      end

      it "updates the scan to failed with an error_message" do
        subject.scan_resource(scan:)

        expect(scan.reload.workflow_state).to eq("failed")
      end

      it "updates the scan with an error_message" do
        subject.scan_resource(scan:)

        expect(scan.reload.error_message).to eq("Failure")
      end
    end
  end
end
