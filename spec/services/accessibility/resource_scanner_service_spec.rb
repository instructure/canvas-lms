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
  let(:wiki_page) { wiki_page_model(course:, body: "<ul><li>foo</li></ul>") }

  describe "#call" do
    let(:delay_mock) { instance_double(described_class) }

    before do
      allow(subject).to receive(:delay).and_return(delay_mock)
      allow(delay_mock).to receive(:scan_resource)
    end

    context "when the scan is not present" do
      it "creates a scan for the resource" do
        described_class.call(resource: wiki_page)

        scan = AccessibilityResourceScan.where(context: wiki_page).first
        expect(scan).to be_present
      end

      it "enqueues a delayed job for scanning the resource" do
        expect(subject).to receive(:delay)
          .with(
            n_strand: ["resource_accessibility_scan", course.account.global_id],
            singleton: "resource_accessibility_scan_#{wiki_page.global_id}_wiki_page",
            priority: 20
          )
          .and_return(delay_mock)
        expect(delay_mock).to receive(:scan_resource)

        subject.call
      end

      it "includes the resource class name in the singleton to avoid conflicts between different resource types" do
        assignment = assignment_model(course:)
        # Simulate same ID scenario by mocking global_id
        allow(wiki_page).to receive(:global_id).and_return(123)
        allow(assignment).to receive(:global_id).and_return(123)

        wiki_page_service = described_class.new(resource: wiki_page)
        assignment_service = described_class.new(resource: assignment)

        wiki_page_delay_mock = instance_double(described_class)
        assignment_delay_mock = instance_double(described_class)

        allow(wiki_page_service).to receive(:delay).and_return(wiki_page_delay_mock)
        allow(assignment_service).to receive(:delay).and_return(assignment_delay_mock)
        allow(wiki_page_delay_mock).to receive(:scan_resource)
        allow(assignment_delay_mock).to receive(:scan_resource)

        # Verify WikiPage gets WikiPage in singleton
        expect(wiki_page_service).to receive(:delay)
          .with(
            n_strand: ["resource_accessibility_scan", course.account.global_id],
            singleton: "resource_accessibility_scan_123_wiki_page",
            priority: 20
          )
          .and_return(wiki_page_delay_mock)

        # Verify Assignment gets Assignment in singleton
        expect(assignment_service).to receive(:delay)
          .with(
            n_strand: ["resource_accessibility_scan", course.account.global_id],
            singleton: "resource_accessibility_scan_123_assignment",
            priority: 20
          )
          .and_return(assignment_delay_mock)

        wiki_page_service.call
        assignment_service.call
      end
    end

    context "when the scan is queued" do
      before do
        accessibility_resource_scan_model(course:, context: wiki_page, workflow_state: "queued")
      end

      it "does not enqueue another scan" do
        expect(delay_mock).not_to receive(:scan_resource)

        subject.call
      end
    end

    context "when the scan is completed" do
      let!(:scan) { accessibility_resource_scan_model(course:, context: wiki_page, workflow_state: "completed") }

      it "re-enqueues the scan" do
        described_class.call(resource: wiki_page)

        scan.reload
        expect(scan.workflow_state).to eq("queued")
      end

      it "enqueues a delayed job for scanning the resource" do
        expect(subject).to receive(:delay)
          .with(
            n_strand: ["resource_accessibility_scan", course.account.global_id],
            singleton: "resource_accessibility_scan_#{wiki_page.global_id}_wiki_page",
            priority: 20
          )
          .and_return(delay_mock)
        expect(delay_mock).to receive(:scan_resource)

        subject.call
      end
    end
  end

  describe "#call_sync" do
    it "creates a scan for the resource" do
      subject.call_sync

      scan = AccessibilityResourceScan.where(context: wiki_page).first
      expect(scan).to be_present
    end

    it "does not enqueue a delayed job" do
      expect(subject).not_to receive(:delay)

      subject.call_sync
    end

    it "calls scan_resource synchronously" do
      expect(subject).to receive(:scan_resource).with(scan: kind_of(AccessibilityResourceScan)).and_call_original

      subject.call_sync
    end

    it "returns the scan object" do
      scan = subject.call_sync

      expect(scan).to be_a(AccessibilityResourceScan)
      expect(scan.context).to eq(wiki_page)
    end

    context "when the scan already exists" do
      let!(:existing_scan) { accessibility_resource_scan_model(course:, context: wiki_page, workflow_state: "completed") }

      it "updates the existing scan" do
        scan = subject.call_sync

        expect(scan.id).to eq(existing_scan.id)
        expect(scan.workflow_state).to eq("completed")
      end
    end

    context "when scan_resource completes successfully" do
      it "updates the scan workflow_state to completed" do
        scan = subject.call_sync

        expect(scan.workflow_state).to eq("completed")
      end
    end

    context "when scan_resource fails" do
      before do
        allow_any_instance_of(described_class).to receive(:scan_resource_for_issues).and_raise(StandardError, "Test failure")
      end

      it "marks the scan as failed" do
        scan = subject.call_sync

        expect(scan.workflow_state).to eq("failed")
        expect(scan.error_message).to be_present
        expect(scan.error_message).to match(/^\d+$/) # Error report ID
      end
    end
  end

  describe "#scan_resource" do
    let!(:scan) { accessibility_resource_scan_model(course:, context: wiki_page, workflow_state: "queued") }

    before do
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
    end

    it "updates the scan to in progress" do
      expect_any_instance_of(AccessibilityResourceScan).to receive(:in_progress!)

      subject.scan_resource(scan:)
    end

    context "when the scan completes successfully" do
      context "when there are existing AccessibilityIssue records" do
        let(:existing_issue) do
          accessibility_issue_model(course:, context: wiki_page)
        end

        it "deletes the existing records" do
          subject.scan_resource(scan:)

          expect(AccessibilityIssue.where(context: wiki_page)).not_to exist
        end
      end

      context "when there are existing issues for the scan" do
        before do
          4.times { accessibility_issue_model(accessibility_resource_scan: scan, workflow_state: "active") }
          3.times { accessibility_issue_model(accessibility_resource_scan: scan, workflow_state: "resolved") }
          2.times { accessibility_issue_model(accessibility_resource_scan: scan, workflow_state: "dismissed") }
        end

        it "removes the active issues" do
          subject.scan_resource(scan:)
          expect(AccessibilityIssue.where(context: wiki_page).active.count).to be(0)
        end

        it "keeps the resolved issues" do
          subject.scan_resource(scan:)
          expect(AccessibilityIssue.where(context: wiki_page).resolved.count).to be(3)
        end

        it "keeps the dismissed issues" do
          subject.scan_resource(scan:)
          expect(AccessibilityIssue.where(context: wiki_page).dismissed.count).to be(2)
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

          issues = AccessibilityIssue.where(context: wiki_page)
          expect(AccessibilityIssue.where(context: wiki_page).count).to be(2)
          expect(issues.first.rule_type).to eq(Accessibility::Rules::HeadingsSequenceRule.id)
          expect(issues.second.rule_type).to eq(Accessibility::Rules::HeadingsStartAtH2Rule.id)
        end

        it "updates the scan with the issue count" do
          subject.scan_resource(scan:)

          expect(scan.reload.issue_count).to eq(2)
        end

        it "connects the scan to the issue" do
          subject.scan_resource(scan:)

          issue = AccessibilityIssue.where(context: wiki_page).first
          expect(issue.accessibility_resource_scan).to eq(scan)
        end
      end

      it "updates the scan to completed" do
        subject.scan_resource(scan:)

        expect(scan.reload.workflow_state).to eq("completed")
      end

      it "logs the correct Datadog metrics for a completed scan" do
        subject.scan_resource(scan:)

        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "accessibility.resources_scanned",
          tags: { cluster: scan.course.shard.database_server&.id }
        )
        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "accessibility.pages_scanned",
          tags: { cluster: scan.course.shard.database_server&.id }
        )
      end

      context "when a11y_checker_account_statistics feature flag is enabled" do
        before do
          Account.site_admin.enable_feature!(:a11y_checker_account_statistics)
          Account.site_admin.enable_feature!(:a11y_checker_ga2_features)
        end

        it "queues course statistics calculation" do
          expect(Accessibility::CourseStatisticCalculatorService).to receive(:queue_calculation).with(course)
          subject.scan_resource(scan:)
        end
      end

      context "when a11y_checker_account_statistics feature flag is disabled" do
        it "does not queue course statistics calculation" do
          expect(Accessibility::CourseStatisticCalculatorService).not_to receive(:queue_calculation)
          subject.scan_resource(scan:)
        end
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

        expect(scan.reload.error_message).to be_present
        expect(scan.reload.error_message).to match(/^\d+$/) # Error report ID
      end

      it "logs the correct Datadog metrics for a failed scan" do
        allow(subject).to receive(:scan_resource_for_issues).and_raise(StandardError, "Failure")

        subject.scan_resource(scan:)

        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "accessibility.resources_scanned",
          tags: { cluster: scan.course.shard.database_server&.id }
        )
        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "accessibility.resource_scan_failed",
          tags: { cluster: scan.course.shard.database_server&.id }
        )
      end
    end

    context "when the resource has nil content" do
      context "for a wiki page with nil body" do
        before do
          wiki_page.update!(body: nil)
        end

        it "completes the scan successfully" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("completed")
        end

        it "reports no issues for nil content" do
          subject.scan_resource(scan:)

          expect(scan.reload.issue_count).to eq(0)
          expect(AccessibilityIssue.where(context: wiki_page).count).to be(0)
        end
      end

      context "for an assignment with nil description" do
        subject { described_class.new(resource: assignment) }

        let(:assignment) { assignment_model(course:, description: nil) }
        let!(:scan) { accessibility_resource_scan_model(course:, context: assignment) }

        it "completes the scan successfully" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("completed")
        end

        it "reports no issues for nil content" do
          subject.scan_resource(scan:)

          expect(scan.reload.issue_count).to eq(0)
          expect(AccessibilityIssue.where(context: assignment).count).to be(0)
        end
      end

      context "for a discussion topic with nil message" do
        subject { described_class.new(resource: discussion_topic) }

        let(:discussion_topic) { discussion_topic_model(context: course, message: nil) }
        let!(:scan) { accessibility_resource_scan_model(course:, context: discussion_topic) }

        it "completes the scan successfully" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("completed")
        end

        it "reports no issues for nil content" do
          subject.scan_resource(scan:)

          expect(scan.reload.issue_count).to eq(0)
          expect(AccessibilityIssue.where(context: discussion_topic).count).to be(0)
        end
      end

      context "for a syllabus with nil syllabus_body" do
        subject { described_class.new(resource: Accessibility::SyllabusResource.new(course)) }

        let!(:scan) { accessibility_resource_scan_model(course:, is_syllabus: true) }

        before do
          course.update!(syllabus_body: nil)
        end

        it "completes the scan successfully" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("completed")
        end

        it "reports no issues for nil content" do
          subject.scan_resource(scan:)

          expect(scan.reload.issue_count).to eq(0)
          expect(AccessibilityIssue.where(course:, is_syllabus: true).count).to be(0)
        end
      end
    end

    context "when the resource exceeds size limit" do
      context "for a wiki page" do
        before do
          wiki_page.update!(body: "a" * (Accessibility::ResourceScannerService::MAX_HTML_SIZE + 1))
        end

        it "fails the scan with an error message" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("failed")
          expect(scan.error_message).to eq(
            "This content is too large to check. HTML body must not be greater than 125 KB."
          )
        end
      end

      context "for an assignment" do
        subject { described_class.new(resource: assignment) }

        let(:assignment) { assignment_model(course:) }
        let!(:scan) { accessibility_resource_scan_model(course:, context: assignment) }

        before do
          assignment.update!(description: "a" * (Accessibility::ResourceScannerService::MAX_HTML_SIZE + 1))
        end

        it "fails the scan with an error message" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("failed")
          expect(scan.error_message).to eq(
            "This content is too large to check. HTML body must not be greater than 125 KB."
          )
        end
      end

      context "for an attachment" do
        subject { described_class.new(resource: attachment) }

        let(:attachment) { attachment_model(course:, content_type: "application/pdf") }
        let!(:scan) { accessibility_resource_scan_model(course:, context: attachment) }

        before do
          allow(attachment).to receive(:size).and_return(Accessibility::ResourceScannerService::MAX_PDF_SIZE + 1)
        end

        it "fails the scan with an error message" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("failed")
          expect(scan.error_message).to eq(
            "This file is too large to check. PDF attachments must not be greater than 5 MB."
          )
        end
      end

      context "for a discussion topic" do
        subject { described_class.new(resource: discussion_topic) }

        let(:discussion_topic) { discussion_topic_model(context: course) }
        let!(:scan) { accessibility_resource_scan_model(course:, context: discussion_topic) }

        before do
          discussion_topic.update!(message: "a" * (Accessibility::ResourceScannerService::MAX_HTML_SIZE + 1))
        end

        it "fails the scan with an error message" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("failed")
          expect(scan.error_message).to eq(
            "This content is too large to check. HTML body must not be greater than 125 KB."
          )
        end
      end

      context "for a syllabus" do
        subject { described_class.new(resource: Accessibility::SyllabusResource.new(course)) }

        let!(:scan) { accessibility_resource_scan_model(course:, is_syllabus: true) }

        before do
          course.update!(syllabus_body: "a" * (Accessibility::ResourceScannerService::MAX_HTML_SIZE + 1))
        end

        it "fails the scan with an error message" do
          subject.scan_resource(scan:)

          expect(scan.reload.workflow_state).to eq("failed")
          expect(scan.error_message).to eq(
            "This content is too large to check. HTML body must not be greater than 125 KB."
          )
        end
      end
    end
  end

  describe "#log_to_datadog" do
    let!(:scan) { accessibility_resource_scan_model(course:, context: wiki_page, workflow_state: "completed") }

    before do
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
    end

    it "logs resources_scanned for all resource types" do
      subject.send(:log_to_datadog, scan)

      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
        "accessibility.resources_scanned",
        tags: { cluster: scan.course.shard.database_server&.id }
      )
    end

    context "for a wiki page" do
      it "logs pages_scanned" do
        subject.send(:log_to_datadog, scan)

        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "accessibility.pages_scanned",
          tags: { cluster: scan.course.shard.database_server&.id }
        )
      end
    end

    context "for an assignment" do
      subject { described_class.new(resource: assignment) }

      let(:assignment) { assignment_model(course:) }
      let!(:scan) { accessibility_resource_scan_model(course:, context: assignment, workflow_state: "completed") }

      it "logs assignments_scanned" do
        subject.send(:log_to_datadog, scan)

        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "accessibility.assignments_scanned",
          tags: { cluster: scan.course.shard.database_server&.id }
        )
      end
    end

    context "for a discussion topic" do
      subject { described_class.new(resource: discussion_topic) }

      let(:discussion_topic) { discussion_topic_model(context: course) }
      let!(:scan) { accessibility_resource_scan_model(course:, context: discussion_topic, workflow_state: "completed") }

      it "logs discussion_topics_scanned" do
        subject.send(:log_to_datadog, scan)

        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "accessibility.discussion_topics_scanned",
          tags: { cluster: scan.course.shard.database_server&.id }
        )
      end
    end

    context "for a syllabus" do
      subject { described_class.new(resource: Accessibility::SyllabusResource.new(course)) }

      let!(:scan) { accessibility_resource_scan_model(course:, is_syllabus: true, workflow_state: "completed") }

      it "logs syllabus_scanned" do
        subject.send(:log_to_datadog, scan)

        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
          "accessibility.syllabus_scanned",
          tags: { cluster: scan.course.shard.database_server&.id }
        )
      end
    end
  end
end
