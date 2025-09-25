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

require_relative "../spec_helper"
require_relative "../lti_spec_helper"

describe AssetProcessorReportHelper do
  include LtiSpecHelper
  include AssetProcessorReportHelper

  before do
    # For text_entry scenario
    course_with_student(active_all: true)
    @domain_root_account = @course.root_account

    @assignment_text = assignment_model({ course: @course, submission_types: "online_text_entry" })
    @submission_text = @assignment_text.submit_homework(@student, submission_type: "online_text_entry", body: "Text entry answer")
    # Create a Lti::Asset for the text entry submission (no attachment, but with submission_attempt)
    @asset_text = Lti::Asset.create!(submission_id: @submission_text.id, attachment_id: nil, submission_attempt: @submission_text.attempt)
    @ap_text = lti_asset_processor_model(tool: @tool, assignment: @assignment_text, title: "Text Entry AP")
    @apreport_text = lti_asset_report_model(
      asset_processor: @ap_text,
      asset: @asset_text,
      title: "Text Entry Asset Report",
      processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
      visible_to_owner: true
    )

    @assignment = assignment_model({ course: @course, submission_types: "online_upload" })
    @attachment1 = attachment_with_context @student, { display_name: "a1.txt", uploaded_data: StringIO.new("hello") }
    @attachment2 = attachment_with_context @student, { display_name: "a2.txt", uploaded_data: StringIO.new("world") }
    @tool = new_valid_external_tool(@course)
    @ap = lti_asset_processor_model(tool: @tool, assignment: @assignment, title: "Live AP")
    @ap_deleted = lti_asset_processor_model(tool: @tool, assignment: @assignment, title: "Deleted AP")
    @submission = @assignment.submit_homework(@student, attachments: [@attachment1, @attachment2])
    @context = @course
    @apreport1 = lti_asset_report_model(
      asset_processor: @ap,
      asset: Lti::Asset.find_by(attachment: @attachment1),
      title: "Asset Report 1",
      processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
      visible_to_owner: true
    )
    @apreport2 = lti_asset_report_model(
      asset_processor: @ap,
      asset: Lti::Asset.find_by(attachment: @attachment2),
      title: "Asset Report 2",
      processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
      visible_to_owner: true
    )
    @ap_deletedreport = lti_asset_report_model(
      asset_processor: @ap_deleted,
      asset: Lti::Asset.find_by(attachment: @attachment2),
      title: "Deleted Asset Report",
      processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
      visible_to_owner: true
    )
    @ap_deleted.destroy
  end

  describe "#raw_asset_reports" do
    it "returns nil for submission with no reports when other submissions have reports" do
      # Create second student and submission with reports
      second_student = user_with_pseudonym(active_all: true)
      second_attachment = attachment_with_context(second_student, { display_name: "second.txt", uploaded_data: StringIO.new("second") })
      second_submission = @assignment.submit_homework(second_student, attachments: [second_attachment])
      lti_asset_report_model(
        asset_processor: @ap,
        asset: Lti::Asset.find_by(attachment: second_attachment),
        processing_progress: Lti::AssetReport::PROGRESS_PENDING,
        visible_to_owner: true
      )

      # Create third submission with no reports
      third_student = user_with_pseudonym(active_all: true)
      third_submission = @assignment.submit_homework(third_student)

      # Test multiple submissions where one has no reports
      results = raw_asset_reports(submission_ids: [third_submission.id, second_submission.id], for_student: true)

      expect(results[third_submission.id]).to be_nil
      expect(results[second_submission.id]).to eq([])
    end
  end

  describe "#asset_reports_info_for_display" do
    it "returns asset reports for a text_entry submission (no attachment, with submission_attempt)" do
      reports = asset_reports_info_for_display(submission: @submission_text)
      expect(reports).to be_a(Array)
      expect(reports.length).to eq(1)
      expect(reports.first[:title]).to eq("Text Entry Asset Report")
      expect(reports.first[:asset][:attachmentId]).to be_nil
      expect(reports.first[:asset][:submissionAttempt]).to eq(@submission_text.attempt)
    end

    it "returns asset reports for the submission" do
      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.length).to eq(2)
      expect(reports.pluck(:title)).to include("Asset Report 1", "Asset Report 2")
      expect(reports.pluck(:title)).not_to include("Deleted Asset Report")
    end

    it "returns nil when submission is blank" do
      reports = asset_reports_info_for_display(submission: nil)
      expect(reports).to be_nil
    end

    it "returns nil when no reports exist for the submission" do
      Lti::AssetReport.where(asset_processor: @ap).destroy_all
      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to be_nil
    end

    it "returns empty array when there are visible reports but none are processed" do
      # Set all visible reports to a non-processed status
      @apreport1.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
      @apreport2.update!(processing_progress: Lti::AssetReport::PROGRESS_FAILED)
      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to eq([])
    end

    it "returns nil when all reports for the submission are not visible to owner" do
      @apreport1.update!(visible_to_owner: false)
      @apreport2.update!(visible_to_owner: false)

      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to be_nil
    end

    it "does not include reports with PROGRESS_FAILED status" do
      failed_asset = Lti::Asset.find_by(attachment: @attachment1)
      lti_asset_report_model(
        asset_processor: @ap,
        asset: failed_asset,
        title: "Failed Report",
        processing_progress: Lti::AssetReport::PROGRESS_FAILED,
        report_type: "unique_failed_report_type",
        visible_to_owner: true
      )

      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.pluck(:title)).to include("Asset Report 1", "Asset Report 2")
      expect(reports.pluck(:title)).not_to include("Failed Report")
    end

    it "does not include reports with non-processed statuses" do
      asset = Lti::Asset.find_by(attachment: @attachment1)

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Processing Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSING,
        report_type: "processing_report_type",
        visible_to_owner: true
      )

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Pending Report",
        processing_progress: Lti::AssetReport::PROGRESS_PENDING,
        report_type: "pending_report_type",
        visible_to_owner: true
      )

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Pending Manual Report",
        processing_progress: Lti::AssetReport::PROGRESS_PENDING_MANUAL,
        report_type: "pending_manual_report_type",
        visible_to_owner: true
      )

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Not Processed Report",
        processing_progress: Lti::AssetReport::PROGRESS_NOT_PROCESSED,
        report_type: "not_processed_report_type",
        visible_to_owner: true
      )

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Not Ready Report",
        processing_progress: Lti::AssetReport::PROGRESS_NOT_READY,
        report_type: "not_ready_report_type",
        visible_to_owner: true
      )

      # Create an additional processed report to test filtering
      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Processed Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        report_type: "processed_report_type",
        visible_to_owner: true
      )

      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to be_a(Array)

      # Should include our original processed reports and the new processed report
      expect(reports.pluck(:title)).to include("Asset Report 1", "Asset Report 2", "Processed Report")

      # Should not include any of the non-processed reports
      filtered_titles = [
        "Processing Report",
        "Pending Report",
        "Pending Manual Report",
        "Not Processed Report",
        "Not Ready Report"
      ]
      filtered_titles.each do |title|
        expect(reports.map { |r| r[:title] }).not_to include(title)
      end
    end

    it "does not include reports with visible_to_owner set to false" do
      asset = Lti::Asset.find_by(attachment: @attachment1)

      # Create a report with visible_to_owner: false
      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Hidden Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        visible_to_owner: false,
        report_type: "hidden_report_type"
      )

      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.pluck(:title)).to include("Asset Report 1", "Asset Report 2")
      expect(reports.pluck(:title)).not_to include("Hidden Report")
    end

    it "returns nil if lti_asset_processor feature flag is disabled" do
      @submission.root_account.disable_feature!(:lti_asset_processor)

      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to be_nil
    end

    it "returns all ids as strings (For graphql compat and JSON max int limit safety)" do
      reports = asset_reports_info_for_display(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.length).to eq(2)

      expect(reports.pluck(:_id)).to all(be_a(String))
      expect(reports.pluck(:_id)).to match_array([@apreport1.id.to_s, @apreport2.id.to_s])
      expect(reports.pluck(:processorId)).to all(be_a(String))
      expect(reports.pluck(:asset).pluck(:attachmentId)).to all(be_a(String))
    end
  end

  # TODO: remove after refactor (INTEROP-9588)
  describe "#asset_reports_legacy_format" do
    it "returns asset reports for a text_entry submission (no attachment, with submission_attempt)" do
      reports = asset_reports_legacy_format(submission: @submission_text)
      expect(reports).to be_a(Array)
      expect(reports.length).to eq(1)
      expect(reports.first[:title]).to eq("Text Entry Asset Report")
      expect(reports.first[:asset][:attachment_id]).to be_nil
      expect(reports.first[:asset][:submission_attempt]).to eq(@submission_text.attempt)
    end

    it "returns asset reports for the submission" do
      reports = asset_reports_legacy_format(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.length).to eq(2)
      expect(reports.pluck(:title)).to include("Asset Report 1", "Asset Report 2")
      expect(reports.pluck(:title)).not_to include("Deleted Asset Report")
    end

    it "returns nil when submission is blank" do
      reports = asset_reports_legacy_format(submission: nil)
      expect(reports).to be_nil
    end

    it "returns nil when no reports exist for the submission" do
      Lti::AssetReport.where(asset_processor: @ap).destroy_all
      reports = asset_reports_legacy_format(submission: @submission)
      expect(reports).to be_nil
    end

    it "returns empty array when there are visible reports but none are processed" do
      # Set all visible reports to a non-processed status
      @apreport1.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
      @apreport2.update!(processing_progress: Lti::AssetReport::PROGRESS_FAILED)
      reports = asset_reports_legacy_format(submission: @submission)
      expect(reports).to eq([])
    end

    it "returns nil when all reports for the submission are not visible to owner" do
      @apreport1.update!(visible_to_owner: false)
      @apreport2.update!(visible_to_owner: false)

      reports = asset_reports_legacy_format(submission: @submission)
      expect(reports).to be_nil
    end

    it "does not include reports with PROGRESS_FAILED status" do
      failed_asset = Lti::Asset.find_by(attachment: @attachment1)
      lti_asset_report_model(
        asset_processor: @ap,
        asset: failed_asset,
        title: "Failed Report",
        processing_progress: Lti::AssetReport::PROGRESS_FAILED,
        report_type: "unique_failed_report_type",
        visible_to_owner: true
      )

      reports = asset_reports_legacy_format(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.pluck(:title)).to include("Asset Report 1", "Asset Report 2")
      expect(reports.pluck(:title)).not_to include("Failed Report")
    end

    it "does not include reports with non-processed statuses" do
      asset = Lti::Asset.find_by(attachment: @attachment1)

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Processing Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSING,
        report_type: "processing_report_type",
        visible_to_owner: true
      )

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Pending Report",
        processing_progress: Lti::AssetReport::PROGRESS_PENDING,
        report_type: "pending_report_type",
        visible_to_owner: true
      )

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Pending Manual Report",
        processing_progress: Lti::AssetReport::PROGRESS_PENDING_MANUAL,
        report_type: "pending_manual_report_type",
        visible_to_owner: true
      )

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Not Processed Report",
        processing_progress: Lti::AssetReport::PROGRESS_NOT_PROCESSED,
        report_type: "not_processed_report_type",
        visible_to_owner: true
      )

      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Not Ready Report",
        processing_progress: Lti::AssetReport::PROGRESS_NOT_READY,
        report_type: "not_ready_report_type",
        visible_to_owner: true
      )

      # Create an additional processed report to test filtering
      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Processed Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        report_type: "processed_report_type",
        visible_to_owner: true
      )

      reports = asset_reports_legacy_format(submission: @submission)
      expect(reports).to be_a(Array)

      # Should include our original processed reports and the new processed report
      expect(reports.pluck(:title)).to include("Asset Report 1", "Asset Report 2", "Processed Report")

      # Should not include any of the non-processed reports
      filtered_titles = [
        "Processing Report",
        "Pending Report",
        "Pending Manual Report",
        "Not Processed Report",
        "Not Ready Report"
      ]
      filtered_titles.each do |title|
        expect(reports.map { |r| r[:title] }).not_to include(title)
      end
    end

    it "does not include reports with visible_to_owner set to false" do
      asset = Lti::Asset.find_by(attachment: @attachment1)

      # Create a report with visible_to_owner: false
      lti_asset_report_model(
        asset_processor: @ap,
        asset:,
        title: "Hidden Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        visible_to_owner: false,
        report_type: "hidden_report_type"
      )

      reports = asset_reports_legacy_format(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.pluck(:title)).to include("Asset Report 1", "Asset Report 2")
      expect(reports.pluck(:title)).not_to include("Hidden Report")
    end

    it "returns nil if lti_asset_processor feature flag is disabled" do
      @submission.root_account.disable_feature!(:lti_asset_processor)

      reports = asset_reports_legacy_format(submission: @submission)
      expect(reports).to be_nil
    end
  end

  describe "#asset_processors" do
    it "returns asset processors for the assignment" do
      processors = asset_processors(assignment: @assignment)
      expect(processors).to be_a(Array)
      expect(processors.length).to eq(1) # One active processor
      expect(processors.first[:title]).to eq("Live AP")
      expect(processors.pluck(:title)).not_to include("Deleted AP")
    end

    it "returns empty array when no processors are attached to the assignment" do
      @ap.destroy
      processors = asset_processors(assignment: @assignment)
      expect(processors).to eq([])
    end

    it "returns nil if lti_asset_processor feature flag is disabled" do
      @domain_root_account.disable_feature!(:lti_asset_processor)
      processors = asset_processors(assignment: @assignment)
      expect(processors).to be_nil
    end
  end

  shared_context "group assignment setup" do
    let(:group_category) { @course.group_categories.create!(name: "Group Category") }
    let(:group1) { group_category.groups.create!(name: "Test Group 1", context: @course) }
    let(:group2) { group_category.groups.create!(name: "Test Group 2", context: @course) }

    let(:group1_student1) { student_in_course(course: @course).user }
    let(:group1_student2) { student_in_course(course: @course).user }
    let(:group2_student1) { student_in_course(course: @course).user }
    let(:group2_student2) { student_in_course(course: @course).user }

    let(:group_assignment) { assignment_model(course: @course, group_category:) }
    let(:group_asset_processor) { lti_asset_processor_model(tool: @tool, assignment: group_assignment) }

    let(:group1_sub1) do
      group1.add_user(group1_student1)
      group_assignment.submissions.find_by(user: group1_student1).tap { |s| s.update!(group: group1) }
    end
    let(:group1_sub2) do
      group1.add_user(group1_student2)
      group_assignment.submissions.find_by(user: group1_student2).tap { |s| s.update!(group: group1) }
    end
    let(:group2_sub1) do
      group2.add_user(group2_student1)
      group_assignment.submissions.find_by(user: group2_student1).tap { |s| s.update!(group: group2) }
    end
    let(:group2_sub2) do
      group2.add_user(group2_student2)
      group_assignment.submissions.find_by(user: group2_student2).tap { |s| s.update!(group: group2) }
    end

    let(:group1_student1_attachment) { attachment_with_context(group1_student1, display_name: "group1_file.txt", uploaded_data: StringIO.new("group1 content")) }
    let(:group2_student1_attachment) { attachment_with_context(group2_student1, display_name: "group2_file.txt", uploaded_data: StringIO.new("group2 content")) }

    let(:group1_student1_asset) { lti_asset_model(submission: group1_sub1, attachment: group1_student1_attachment) }
    let(:group2_student1_asset) { lti_asset_model(submission: group2_sub1, attachment: group2_student1_attachment) }

    let(:group1_student2_attachment) { attachment_with_context(group1_student2, display_name: "group1_student2_file.txt", uploaded_data: StringIO.new("group1 student2 content")) }
    let(:group2_student2_attachment) { attachment_with_context(group2_student2, display_name: "group2_student2_file.txt", uploaded_data: StringIO.new("group2 student2 content")) }

    let(:group1_student2_asset) { lti_asset_model(submission: group1_sub2, attachment: group1_student2_attachment) }
    let(:group2_student2_asset) { lti_asset_model(submission: group2_sub2, attachment: group2_student2_attachment) }

    let(:group1_student1_report) do
      lti_asset_report_model(
        asset_processor: group_asset_processor,
        asset: group1_student1_asset,
        title: "Group 1 Student 1 Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        visible_to_owner: true
      )
    end
    let(:group2_student1_report) do
      lti_asset_report_model(
        asset_processor: group_asset_processor,
        asset: group2_student1_asset,
        title: "Group 2 Student 1 Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        visible_to_owner: true
      )
    end
    let(:group1_student2_report) do
      lti_asset_report_model(
        asset_processor: group_asset_processor,
        asset: group1_student2_asset,
        title: "Group 1 Student 2 Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        visible_to_owner: true
      )
    end
    let(:group2_student2_report) do
      lti_asset_report_model(
        asset_processor: group_asset_processor,
        asset: group2_student2_asset,
        title: "Group 2 Student 2 Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        visible_to_owner: true
      )
    end

    before do
      group1_student1_report
      group1_student2_report
      group2_student1_report
      group2_student2_report
    end
  end

  describe "#raw_asset_reports with group assignment" do
    include_context "group assignment setup"

    it "includes reports from group mate submissions for students" do
      reports = raw_asset_reports(submission_ids: [group1_sub2.id], for_student: true)

      expect(reports[group1_sub2.id]).to be_a(Array)
      expect(reports[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
      expect(reports[group1_sub2.id]).not_to include(group2_student1_report, group2_student2_report)
    end

    it "includes reports from group mate submissions for teachers" do
      reports = raw_asset_reports(submission_ids: [group1_sub2.id], for_student: false)

      expect(reports[group1_sub2.id]).to be_a(Array)
      expect(reports[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
      expect(reports[group1_sub2.id]).not_to include(group2_student1_report, group2_student2_report)
    end

    it "returns reports for multiple group submissions" do
      reports = raw_asset_reports(submission_ids: [group1_sub2.id, group2_sub2.id], for_student: true)

      expect(reports[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
      expect(reports[group1_sub2.id]).not_to include(group2_student1_report, group2_student2_report)

      expect(reports[group2_sub2.id]).to include(group2_student1_report, group2_student2_report)
      expect(reports[group2_sub2.id]).not_to include(group1_student1_report, group1_student2_report)
    end

    it "handles submissions not in groups" do
      reports = raw_asset_reports(submission_ids: [@submission.id], for_student: true)

      expect(reports[@submission.id]).to be_a(Array)
      expect(reports[@submission.id]).to include(@apreport1)
    end

    it "filters by visible_to_owner for students" do
      group1_student1_report.update!(visible_to_owner: false)
      group1_student2_report.update!(visible_to_owner: false)

      reports = raw_asset_reports(submission_ids: [group1_sub2.id], for_student: true)
      expect(reports[group1_sub2.id]).to be_nil
    end

    it "does not filter by visible_to_owner for teachers" do
      group1_student1_report.update!(visible_to_owner: false)
      group1_student2_report.update!(visible_to_owner: false)

      reports = raw_asset_reports(submission_ids: [group1_sub2.id], for_student: false)
      expect(reports[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
    end

    it "returns empty array when there are visible reports but none processed for students" do
      group1_student1_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
      group1_student2_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)

      reports = raw_asset_reports(submission_ids: [group1_sub2.id], for_student: true)
      expect(reports[group1_sub2.id]).to eq([])
    end

    it "returns all reports regardless of processing status for teachers" do
      group1_student1_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
      group1_student2_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)

      reports = raw_asset_reports(submission_ids: [group1_sub2.id], for_student: false)
      expect(reports[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
    end
  end

  describe "#asset_reports_info_for_display with group assignments" do
    include_context "group assignment setup"

    it "returns reports from group mate submissions" do
      reports = asset_reports_info_for_display(submission: group1_sub2)

      expect(reports).to be_a(Array)
      expect(reports.pluck(:title)).to \
        match_array(["Group 1 Student 1 Report", "Group 1 Student 2 Report"])
    end

    it "returns nil when no group mate reports exist" do
      group1_student1_report.destroy!
      group1_student2_report.destroy!

      reports = asset_reports_info_for_display(submission: group1_sub2)
      expect(reports).to be_nil
    end

    it "returns empty array when group mate reports exist but are not processed" do
      group1_student1_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
      group1_student2_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)

      reports = asset_reports_info_for_display(submission: group1_sub2)
      expect(reports).to eq([])
    end

    it "returns nil when group mate reports are not visible to owner" do
      group1_student1_report.update!(visible_to_owner: false)
      group1_student2_report.update!(visible_to_owner: false)

      reports = asset_reports_info_for_display(submission: group1_sub2)
      expect(reports).to be_nil
    end
  end

  # TODO: remove after refactor (INTEROP-9588)
  describe "#asset_reports_legacy_format with group assignments" do
    include_context "group assignment setup"

    it "returns reports from group mate submissions" do
      reports = asset_reports_legacy_format(submission: group1_sub2)

      expect(reports).to be_a(Array)
      expect(reports.pluck(:title)).to \
        match_array(["Group 1 Student 1 Report", "Group 1 Student 2 Report"])
    end

    it "returns nil when no group mate reports exist" do
      group1_student1_report.destroy!
      group1_student2_report.destroy!

      reports = asset_reports_legacy_format(submission: group1_sub2)
      expect(reports).to be_nil
    end

    it "returns empty array when group mate reports exist but are not processed" do
      group1_student1_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
      group1_student2_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)

      reports = asset_reports_legacy_format(submission: group1_sub2)
      expect(reports).to eq([])
    end

    it "returns nil when group mate reports are not visible to owner" do
      group1_student1_report.update!(visible_to_owner: false)
      group1_student2_report.update!(visible_to_owner: false)

      reports = asset_reports_legacy_format(submission: group1_sub2)
      expect(reports).to be_nil
    end
  end

  describe "text_entry submission after file_upload submission" do
    it "returns reports for text_entry when there was previous file_upload submission" do
      mixed_assignment = assignment_model(course: @course,
                                          submission_types: "online_upload,online_text_entry")

      attachment = attachment_with_context(@student,
                                           display_name: "test.txt",
                                           uploaded_data: StringIO.new("test content"))
      ap = lti_asset_processor_model(tool: @tool, assignment: mixed_assignment, title: "Mixed AP")
      mixed_assignment.submit_homework(@student, attachments: [attachment])

      file_asset = Lti::Asset.find_by(attachment:)

      lti_asset_report_model(
        asset_processor: ap,
        asset: file_asset,
        title: "File Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        visible_to_owner: true
      )

      text_submission = mixed_assignment.submit_homework(
        @student,
        submission_type: "online_text_entry",
        body: "New text entry"
      )

      expect(text_submission.attachment_associations.count).to be > 0
      expect(text_submission.attachment_ids.to_s).to eq("")

      reports = raw_asset_reports(submission_ids: [text_submission.id], for_student: true)[text_submission.id]

      expect(reports).to be_nil
    end

    it "handles attachment_ids comparison correctly with string conversion" do
      mixed_assignment = assignment_model(course: @course,
                                          submission_types: "online_upload,online_text_entry")

      attachment = attachment_with_context @student,
                                           display_name: "test.txt",
                                           uploaded_data: StringIO.new("test content")
      ap = lti_asset_processor_model(tool: @tool, assignment: mixed_assignment, title: "String Test AP")

      file_submission = mixed_assignment.submit_homework(@student, attachments: [attachment])

      file_asset = Lti::Asset.find_by(attachment:)

      lti_asset_report_model(
        asset_processor: ap,
        asset: file_asset,
        title: "String Comparison Report",
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
        visible_to_owner: true
      )

      attachment_ids_array = file_submission.attachment_ids&.presence&.split(",") || []
      expect(attachment_ids_array).to include(attachment.id.to_s)

      reports = raw_asset_reports(submission_ids: [file_submission.id], for_student: true)[file_submission.id]
      expect(reports).not_to be_nil
      expect(reports.length).to eq(1)
      expect(reports.first[:title]).to eq("String Comparison Report")
    end
  end
end
