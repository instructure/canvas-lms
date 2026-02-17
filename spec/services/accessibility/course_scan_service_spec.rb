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

describe Accessibility::CourseScanService do
  subject { described_class.new(course:) }

  let!(:course) { course_model }

  describe ".queue_scan_course" do
    it "creates a Progress record with the correct tag and context" do
      expect { described_class.queue_course_scan(course) }
        .to change { Progress.where(tag: "course_accessibility_scan", context: course).count }.by(1)
    end

    context "when a scan is already pending" do
      let!(:existing_progress) do
        Progress.create!(tag: "course_accessibility_scan", context: course, workflow_state: "queued")
      end

      it "returns the existing progress without creating a new one" do
        expect { described_class.queue_course_scan(course) }
          .not_to change { Progress.where(tag: "course_accessibility_scan", context: course).count }
        expect(described_class.queue_course_scan(course)).to eq(existing_progress)
      end
    end

    context "when a scan is already running" do
      let!(:existing_progress) do
        Progress.create!(tag: "course_accessibility_scan", context: course, workflow_state: "running")
      end

      it "returns the existing progress without creating a new one" do
        expect { described_class.queue_course_scan(course) }
          .not_to change { Progress.where(tag: "course_accessibility_scan", context: course).count }
        expect(described_class.queue_course_scan(course)).to eq(existing_progress)
      end
    end

    context "when a previous scan is completed" do
      before do
        Progress.create!(tag: "course_accessibility_scan", context: course, workflow_state: "completed")
      end

      it "creates a new progress" do
        expect { described_class.queue_course_scan(course) }
          .to change { Progress.where(tag: "course_accessibility_scan", context: course).count }.by(1)
      end
    end
  end

  describe ".scan" do
    let(:progress) do
      Progress.create!(tag: "course_accessibility_scan", context: course).tap(&:start!)
    end

    before do
      scanner_service_double = instance_double(Accessibility::ResourceScannerService)
      allow(scanner_service_double).to receive(:call_sync)
      allow(scanner_service_double).to receive(:scan_resource)
      allow(Accessibility::ResourceScannerService).to receive(:new).and_return(scanner_service_double)
    end

    it "calls scan_course on a new service instance" do
      service_instance = instance_double(described_class)
      allow(described_class).to receive(:new).with(course:).and_return(service_instance)
      allow(service_instance).to receive(:scan_course)
      allow(service_instance).to receive(:queue_course_statistics)

      described_class.scan(progress)

      expect(service_instance).to have_received(:scan_course)
    end

    it "completes the progress" do
      described_class.scan(progress)
      expect(progress.reload).to be_completed
    end

    context "when a11y_checker_account_statistics feature flag is enabled" do
      before do
        Account.site_admin.enable_feature!(:a11y_checker_account_statistics)
        Account.site_admin.enable_feature!(:a11y_checker_ga2_features)
      end

      it "queues course statistics calculation after scan completes" do
        expect(Accessibility::CourseStatisticCalculatorService).to receive(:queue_calculation).with(course)
        described_class.scan(progress)
      end
    end

    context "when a11y_checker_account_statistics feature flag is disabled" do
      it "does not queue course statistics calculation" do
        expect(Accessibility::CourseStatisticCalculatorService).not_to receive(:queue_calculation)
        described_class.scan(progress)
      end
    end

    context "when an error occurs" do
      before do
        allow_any_instance_of(described_class).to receive(:scan_course).and_raise(StandardError, "Scan failed")
      end

      it "marks the progress as failed" do
        expect { described_class.scan(progress) }.to raise_error(StandardError, "Scan failed")
        expect(progress.reload).to be_failed
      end
    end
  end

  describe "#scan_course" do
    let(:scanner_service_double) { instance_double(Accessibility::ResourceScannerService) }

    before do
      allow(scanner_service_double).to receive(:call_sync)
      allow(scanner_service_double).to receive(:scan_resource)
      allow(Accessibility::ResourceScannerService).to receive(:new).and_return(scanner_service_double)
    end

    context "when scanning wiki pages" do
      let!(:wiki_page1) { wiki_page_model(course:) }
      let!(:wiki_page2) { wiki_page_model(course:) }

      before do
        wiki_page2.destroy!
        subject.scan_course
      end

      it "scans the active wiki page" do
        expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: wiki_page1)
      end

      it "does not scan the deleted wiki page" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: wiki_page2)
      end
    end

    context "when scanning assignments" do
      let!(:assignment1) { assignment_model(course:) }
      let!(:assignment2) { assignment_model(course:) }
      let!(:quiz_lti_assignment) { new_quizzes_assignment(course:) }
      let!(:classic_quiz) { course.quizzes.create!(title: "Classic Quiz", quiz_type: "assignment") }
      let!(:classic_quiz_assignment) { classic_quiz.assignment }
      let!(:external_tool_assignment) do
        course.assignments.create!(
          title: "External Tool Assignment",
          submission_types: "external_tool"
        )
      end

      before do
        assignment2.destroy!
        subject.scan_course
      end

      it "scans the active assignment" do
        expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: assignment1)
      end

      it "does not scan the deleted assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: assignment2)
      end

      it "does not scan the New Quizzes assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: quiz_lti_assignment)
      end

      it "does not scan the Classic Quiz assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: classic_quiz_assignment)
      end

      it "does not scan the external tool assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: external_tool_assignment)
      end
    end

    context "when scanning additional resources" do
      let!(:discussion_topic1) { discussion_topic_model(context: course) }
      let!(:discussion_topic2) { discussion_topic_model(context: course) }
      let!(:discussion_topic3) { discussion_topic_model(context: course) }
      let!(:announcement) { course.announcements.create!(title: "Test Announcement", message: "Test message") }
      let!(:delayed_announcement) { course.announcements.create!(title: "Test Announcement", message: "Test message", workflow_state: "post_delayed") }
      let!(:deleted_announcement) { course.announcements.create!(title: "Test Announcement", message: "Test message") }
      let!(:graded_discussion) do
        assignment = course.assignments.create!(title: "Graded Discussion")
        course.discussion_topics.create!(title: "Graded Discussion", assignment:)
      end

      before do
        discussion_topic2.unpublish!
        discussion_topic3.destroy!
        deleted_announcement.destroy!
      end

      context "when a11y_checker_additional_resources feature flag is enabled" do
        before do
          Account.site_admin.enable_feature!(:a11y_checker_additional_resources)
          Account.site_admin.enable_feature!(:a11y_checker_ga2_features)
          subject.scan_course
        end

        it "scans the published and unpublished discussion topics" do
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: discussion_topic1)
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: discussion_topic2)
        end

        it "does not scan the deleted discussion topic" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: discussion_topic3)
        end

        it "scans announcements and delayed announcements" do
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: announcement)
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: delayed_announcement)
        end

        it "does not scan deleted announcements" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: deleted_announcement)
        end

        it "does not scan graded discussions" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: graded_discussion)
        end

        it "creates scan records with announcement_id filled and not discussion_topic_id" do
          # Override parent stubs to allow real implementation
          allow(Accessibility::ResourceScannerService).to receive(:new).and_call_original
          allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:call_sync).and_call_original
          allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:scan_resource).and_wrap_original do |_, scan:|
            scan.update!(
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end

          subject.scan_course

          scan = AccessibilityResourceScan.find_by(announcement_id: announcement.id)
          expect(scan.announcement_id).to eq(announcement.id)
          expect(scan.discussion_topic_id).to be_nil
          expect(scan.context).to eq(announcement)
          expect(scan.context_type).to eq("Announcement")
        end
      end

      context "when a11y_checker_additional_resources feature flag is disabled" do
        before do
          subject.scan_course
        end

        it "does not scan any discussion topics" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: discussion_topic1)
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: discussion_topic2)
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: discussion_topic3)
        end

        it "does not scan any announcements" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: announcement)
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: delayed_announcement)
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: deleted_announcement)
        end
      end
    end

    context "when scanning syllabus" do
      context "when a11y_checker_additional_resources feature flag is enabled" do
        before do
          Account.site_admin.enable_feature!(:a11y_checker_additional_resources)
          Account.site_admin.enable_feature!(:a11y_checker_ga2_features)
        end

        context "when course has a syllabus" do
          before do
            course.update!(syllabus_body: "<p>Course syllabus content</p>")
            subject.scan_course
          end

          it "scans the syllabus" do
            expect(Accessibility::ResourceScannerService).to have_received(:new).with(
              resource: an_instance_of(Accessibility::SyllabusResource)
            )
          end
        end

        context "when course has no syllabus" do
          before do
            course.update!(syllabus_body: nil)
            subject.scan_course
          end

          it "does not scan the syllabus" do
            expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(
              resource: an_instance_of(Accessibility::SyllabusResource)
            )
          end
        end

        context "when course has empty syllabus" do
          before do
            course.update!(syllabus_body: "")
            subject.scan_course
          end

          it "does not scan the syllabus" do
            expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(
              resource: an_instance_of(Accessibility::SyllabusResource)
            )
          end
        end
      end

      context "when a11y_checker_additional_resources feature flag is disabled" do
        before do
          course.update!(syllabus_body: "<p>Course syllabus content</p>")
          subject.scan_course
        end

        it "does not scan the syllabus" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(
            resource: an_instance_of(Accessibility::SyllabusResource)
          )
        end
      end

      context "when scanning syllabus with existing scan record" do
        before do
          Account.site_admin.enable_feature!(:a11y_checker_additional_resources)
          Account.site_admin.enable_feature!(:a11y_checker_ga2_features)
          course.update!(syllabus_body: "<p>Course syllabus content</p>")
        end

        context "when no scan exists for syllabus" do
          it "calls call_sync" do
            scanner_service = instance_double(Accessibility::ResourceScannerService)
            allow(Accessibility::ResourceScannerService).to receive(:new).with(
              resource: an_instance_of(Accessibility::SyllabusResource)
            ).and_return(scanner_service)
            allow(scanner_service).to receive(:call_sync)
            allow(scanner_service).to receive(:scan_resource)

            subject.scan_course

            expect(scanner_service).to have_received(:call_sync)
            expect(scanner_service).not_to have_received(:scan_resource)
          end
        end

        context "when a scan exists for syllabus" do
          let!(:existing_syllabus_scan) do
            AccessibilityResourceScan.create!(
              course:,
              is_syllabus: true,
              workflow_state: "completed",
              resource_workflow_state: "published",
              issue_count: 2
            )
          end

          it "calls scan_resource with the existing scan" do
            scanner_service = instance_double(Accessibility::ResourceScannerService)
            allow(Accessibility::ResourceScannerService).to receive(:new).with(
              resource: an_instance_of(Accessibility::SyllabusResource)
            ).and_return(scanner_service)
            allow(scanner_service).to receive(:call_sync)
            allow(scanner_service).to receive(:scan_resource)

            subject.scan_course

            expect(scanner_service).to have_received(:scan_resource).with(scan: existing_syllabus_scan)
            expect(scanner_service).not_to have_received(:call_sync)
          end
        end
      end
    end

    context "when determining if resources need scanning" do
      before do
        Account.site_admin.enable_feature!(:a11y_checker_additional_resources)
        Account.site_admin.enable_feature!(:a11y_checker_ga2_features)
      end

      let!(:wiki_page) { wiki_page_model(course:) }
      let!(:assignment) { assignment_model(course:) }
      let!(:discussion_topic) { discussion_topic_model(context: course) }
      let!(:announcement) { course.announcements.create!(title: "Test Announcement", message: "Test message") }

      before do
        course.update!(syllabus_body: "<p>Course syllabus content</p>")
      end

      context "when there is no previous scan" do
        it "scans the wiki page" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: wiki_page)
        end

        it "scans the assignment" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: assignment)
        end

        it "scans the discussion topic" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: discussion_topic)
        end

        it "scans the announcement" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: announcement)
        end

        it "scans the syllabus" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(
            resource: an_instance_of(Accessibility::SyllabusResource)
          )
        end
      end

      context "when resource has not been updated since last scan" do
        before do
          Account.site_admin.enable_feature!(:a11y_checker_course_scan_conditional_resource_scan)
          Timecop.freeze(wiki_page.updated_at + 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              context: wiki_page,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
          Timecop.freeze(assignment.updated_at + 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              context: assignment,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
          Timecop.freeze(discussion_topic.updated_at + 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              context: discussion_topic,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
          Timecop.freeze(announcement.updated_at + 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              context: announcement,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
          Timecop.freeze(course.updated_at + 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              is_syllabus: true,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
        end

        it "does not scan the wiki page" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: wiki_page)
        end

        it "does not scan the assignment" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: assignment)
        end

        it "does not scan the discussion topic" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: discussion_topic)
        end

        it "does not scan the announcement" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: announcement)
        end

        it "does not scan the syllabus" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(
            resource: an_instance_of(Accessibility::SyllabusResource)
          )
        end
      end

      context "when resource has been updated since last scan" do
        before do
          Account.site_admin.enable_feature!(:a11y_checker_course_scan_conditional_resource_scan)
          Timecop.freeze(wiki_page.updated_at - 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              context: wiki_page,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
          Timecop.freeze(assignment.updated_at - 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              context: assignment,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
          Timecop.freeze(discussion_topic.updated_at - 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              context: discussion_topic,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
          Timecop.freeze(announcement.updated_at - 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              context: announcement,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
          Timecop.freeze(course.updated_at - 1.hour) do
            AccessibilityResourceScan.create!(
              course:,
              is_syllabus: true,
              workflow_state: :completed,
              resource_workflow_state: :published,
              issue_count: 0
            )
          end
        end

        it "scans the wiki page" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: wiki_page)
        end

        it "scans the assignment" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: assignment)
        end

        it "scans the discussion topic" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: discussion_topic)
        end

        it "scans the announcement" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: announcement)
        end

        it "scans the syllabus" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:new).with(
            resource: an_instance_of(Accessibility::SyllabusResource)
          )
        end
      end

      context "when a11y_checker_course_scan_conditional_resource_scan feature flag is disabled" do
        before do
          Account.site_admin.disable_feature!(:a11y_checker_course_scan_conditional_resource_scan)
        end

        context "when resource has not been updated since last scan" do
          before do
            Timecop.freeze(wiki_page.updated_at + 1.hour) do
              AccessibilityResourceScan.create!(
                course:,
                context: wiki_page,
                workflow_state: :completed,
                resource_workflow_state: :published,
                issue_count: 0
              )
            end
            Timecop.freeze(assignment.updated_at + 1.hour) do
              AccessibilityResourceScan.create!(
                course:,
                context: assignment,
                workflow_state: :completed,
                resource_workflow_state: :published,
                issue_count: 0
              )
            end
          end

          it "scans the wiki page regardless of timestamp" do
            subject.scan_course
            expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: wiki_page)
          end

          it "scans the assignment regardless of timestamp" do
            subject.scan_course
            expect(Accessibility::ResourceScannerService).to have_received(:new).with(resource: assignment)
          end
        end
      end

      context "when a11y_checker_course_scan_conditional_resource_scan feature flag is enabled" do
        before do
          Account.site_admin.enable_feature!(:a11y_checker_course_scan_conditional_resource_scan)
        end

        context "when resource has not been updated since last scan" do
          before do
            Timecop.freeze(wiki_page.updated_at + 1.hour) do
              AccessibilityResourceScan.create!(
                course:,
                context: wiki_page,
                workflow_state: :completed,
                resource_workflow_state: :published,
                issue_count: 0
              )
            end
            Timecop.freeze(assignment.updated_at + 1.hour) do
              AccessibilityResourceScan.create!(
                course:,
                context: assignment,
                workflow_state: :completed,
                resource_workflow_state: :published,
                issue_count: 0
              )
            end
          end

          it "does not scan the wiki page" do
            subject.scan_course
            expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: wiki_page)
          end

          it "does not scan the assignment" do
            subject.scan_course
            expect(Accessibility::ResourceScannerService).not_to have_received(:new).with(resource: assignment)
          end
        end
      end
    end

    context "scan creation and processing" do
      let!(:wiki_page) { wiki_page_model(course:, body: "<p>test</p>") }

      before do
        # Override parent stubs to allow real implementation
        allow(Accessibility::ResourceScannerService).to receive(:new).and_call_original
        allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:call_sync).and_call_original
        allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:scan_resource)
      end

      context "when no scan exists for the resource" do
        it "creates a new scan" do
          expect do
            subject.scan_course
          end.to change { AccessibilityResourceScan.where(wiki_page_id: wiki_page.id).count }.by(1)
        end

        it "creates the scan with correct attributes" do
          subject.scan_course
          scan = AccessibilityResourceScan.where(wiki_page_id: wiki_page.id).first

          expect(scan.course_id).to eq(course.id)
          expect(scan.workflow_state).to eq("queued")
          expect(scan.resource_name).to eq(wiki_page.title)
          expect(scan.resource_workflow_state).to eq("published")
          expect(scan.issue_count).to eq(0)
          expect(scan.error_message).to be_nil
        end

        it "calls call_sync when no existing scan is found" do
          scanner_service = instance_double(Accessibility::ResourceScannerService)
          allow(Accessibility::ResourceScannerService).to receive(:new).and_return(scanner_service)
          allow(scanner_service).to receive(:call_sync)
          allow(scanner_service).to receive(:scan_resource)

          subject.scan_course

          expect(scanner_service).to have_received(:call_sync)
          expect(scanner_service).not_to have_received(:scan_resource)
        end

        it "calls scan_resource with the newly created scan" do
          call_count = 0
          allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:scan_resource) do |_, scan:|
            call_count += 1
            expect(scan).to be_an(AccessibilityResourceScan)
            expect(scan.wiki_page_id).to eq(wiki_page.id)
          end

          subject.scan_course
          expect(call_count).to eq(1)
        end
      end

      context "when a scan already exists for the resource" do
        let!(:existing_scan) do
          AccessibilityResourceScan.create!(
            course:,
            context: wiki_page,
            workflow_state: "completed",
            resource_workflow_state: "published",
            resource_updated_at: wiki_page.updated_at - 1.hour,
            issue_count: 5,
            error_message: nil
          )
        end

        it "does not create a new scan" do
          expect do
            subject.scan_course
          end.not_to change { AccessibilityResourceScan.where(wiki_page_id: wiki_page.id).count }
        end

        it "uses the existing scan" do
          received_scan = nil
          allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:scan_resource) do |_, scan:|
            received_scan = scan
          end

          subject.scan_course
          expect(received_scan).to eq(existing_scan)
        end

        it "calls scan_resource with the existing scan and not call_sync" do
          scanner_service = instance_double(Accessibility::ResourceScannerService)
          allow(Accessibility::ResourceScannerService).to receive(:new).and_return(scanner_service)
          allow(scanner_service).to receive(:call_sync)
          allow(scanner_service).to receive(:scan_resource)

          subject.scan_course

          expect(scanner_service).to have_received(:scan_resource).with(scan: existing_scan)
          expect(scanner_service).not_to have_received(:call_sync)
        end

        it "calls scan_resource with the existing scan" do
          call_count = 0
          allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:scan_resource) do |_, scan:|
            call_count += 1
            expect(scan).to eq(existing_scan)
          end

          subject.scan_course
          expect(call_count).to eq(1)
        end
      end

      context "when scan is queued" do
        before do
          AccessibilityResourceScan.create!(
            course:,
            context: wiki_page,
            workflow_state: "queued",
            resource_workflow_state: "published",
            resource_updated_at: wiki_page.updated_at,
            issue_count: 0,
            error_message: nil
          )
        end

        it "skips processing the resource" do
          call_count = 0
          allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:scan_resource) do
            call_count += 1
          end

          subject.scan_course
          expect(call_count).to eq(0)
        end
      end

      context "when scan is in_progress" do
        before do
          AccessibilityResourceScan.create!(
            course:,
            context: wiki_page,
            workflow_state: "in_progress",
            resource_workflow_state: "published",
            resource_updated_at: wiki_page.updated_at,
            issue_count: 0,
            error_message: nil
          )
        end

        it "skips processing the resource" do
          call_count = 0
          allow_any_instance_of(Accessibility::ResourceScannerService).to receive(:scan_resource) do
            call_count += 1
          end

          subject.scan_course
          expect(call_count).to eq(0)
        end
      end
    end
  end
end
