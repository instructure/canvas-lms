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

describe AssetProcessorStudentHelper do
  include LtiSpecHelper
  include AssetProcessorStudentHelper

  before do
    @domain_root_account = Account.default

    course_with_student(active_all: true)
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

  describe "#asset_reports" do
    it "returns asset reports for the submission" do
      reports = asset_reports(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.length).to eq(2)
      expect(reports.map { |r| r[:title] }).to include("Asset Report 1", "Asset Report 2")
      expect(reports.map { |r| r[:title] }).not_to include("Deleted Asset Report")
    end

    it "returns nil when submission is blank" do
      reports = asset_reports(submission: nil)
      expect(reports).to be_nil
    end

    it "returns nil when no reports exist for the submission" do
      Lti::AssetReport.where(asset_processor: @ap).destroy_all
      reports = asset_reports(submission: @submission)
      expect(reports).to be_nil
    end

    it "returns empty array when there are visible reports but none are processed" do
      # Set all visible reports to a non-processed status
      @apreport1.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
      @apreport2.update!(processing_progress: Lti::AssetReport::PROGRESS_FAILED)
      reports = asset_reports(submission: @submission)
      expect(reports).to eq([])
    end

    it "returns nil when all reports for the submission are not visible to owner" do
      @apreport1.update!(visible_to_owner: false)
      @apreport2.update!(visible_to_owner: false)

      reports = asset_reports(submission: @submission)
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

      reports = asset_reports(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.map { |r| r[:title] }).to include("Asset Report 1", "Asset Report 2")
      expect(reports.map { |r| r[:title] }).not_to include("Failed Report")
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

      reports = asset_reports(submission: @submission)
      expect(reports).to be_a(Array)

      # Should include our original processed reports and the new processed report
      expect(reports.map { |r| r[:title] }).to include("Asset Report 1", "Asset Report 2", "Processed Report")

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

      reports = asset_reports(submission: @submission)
      expect(reports).to be_a(Array)
      expect(reports.map { |r| r[:title] }).to include("Asset Report 1", "Asset Report 2")
      expect(reports.map { |r| r[:title] }).not_to include("Hidden Report")
    end

    it "returns nil if lti_asset_processor feature flag is disabled" do
      @domain_root_account.disable_feature!(:lti_asset_processor)
      reports = asset_reports(submission: @submission)
      expect(reports).to be_nil
    end
  end

  describe "#asset_processors" do
    it "returns asset processors for the assignment" do
      processors = asset_processors(assignment: @assignment)
      expect(processors).to be_a(Array)
      expect(processors.length).to eq(1) # One active processor
      expect(processors.first[:title]).to eq("Live AP")
      expect(processors.map { |p| p[:title] }).not_to include("Deleted AP")
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
end
