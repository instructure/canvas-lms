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
      allow(Accessibility::ResourceScannerService).to receive(:call)
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
    before do
      allow(Accessibility::ResourceScannerService).to receive(:call)
    end

    context "when scanning wiki pages" do
      let!(:wiki_page1) { wiki_page_model(course:) }
      let!(:wiki_page2) { wiki_page_model(course:) }

      before do
        wiki_page2.destroy!
        subject.scan_course
      end

      it "scans the active wiki page" do
        expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: wiki_page1)
      end

      it "does not scan the deleted wiki page" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: wiki_page2)
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
        expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: assignment1)
      end

      it "does not scan the deleted assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: assignment2)
      end

      it "does not scan the New Quizzes assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: quiz_lti_assignment)
      end

      it "does not scan the Classic Quiz assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: classic_quiz_assignment)
      end

      it "does not scan the external tool assignment" do
        expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: external_tool_assignment)
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
          subject.scan_course
        end

        it "scans the published and unpublished discussion topics" do
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: discussion_topic1)
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: discussion_topic2)
        end

        it "does not scan the deleted discussion topic" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: discussion_topic3)
        end

        it "scans announcements and delayed announcements" do
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: announcement)
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: delayed_announcement)
        end

        it "does not scan deleted announcements" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: deleted_announcement)
        end

        it "does not scan graded discussions" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: graded_discussion)
        end

        it "creates scan records with announcement_id filled and not discussion_topic_id" do
          allow(Accessibility::ResourceScannerService).to receive(:call).and_call_original
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
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: discussion_topic1)
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: discussion_topic2)
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: discussion_topic3)
        end

        it "does not scan any announcements" do
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: announcement)
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: delayed_announcement)
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: deleted_announcement)
        end
      end
    end

    context "when determining if resources need scanning" do
      before do
        Account.site_admin.enable_feature!(:a11y_checker_additional_resources)
      end

      let!(:wiki_page) { wiki_page_model(course:) }
      let!(:assignment) { assignment_model(course:) }
      let!(:discussion_topic) { discussion_topic_model(context: course) }
      let!(:announcement) { course.announcements.create!(title: "Test Announcement", message: "Test message") }

      context "when there is no previous scan" do
        it "scans the wiki page" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: wiki_page)
        end

        it "scans the assignment" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: assignment)
        end

        it "scans the discussion topic" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: discussion_topic)
        end

        it "scans the announcement" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: announcement)
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
        end

        it "does not scan the wiki page" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: wiki_page)
        end

        it "does not scan the assignment" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: assignment)
        end

        it "does not scan the discussion topic" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: discussion_topic)
        end

        it "does not scan the announcement" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: announcement)
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
        end

        it "scans the wiki page" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: wiki_page)
        end

        it "scans the assignment" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: assignment)
        end

        it "scans the discussion topic" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: discussion_topic)
        end

        it "scans the announcement" do
          subject.scan_course
          expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: announcement)
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
            expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: wiki_page)
          end

          it "scans the assignment regardless of timestamp" do
            subject.scan_course
            expect(Accessibility::ResourceScannerService).to have_received(:call).with(resource: assignment)
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
            expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: wiki_page)
          end

          it "does not scan the assignment" do
            subject.scan_course
            expect(Accessibility::ResourceScannerService).not_to have_received(:call).with(resource: assignment)
          end
        end
      end
    end
  end
end
