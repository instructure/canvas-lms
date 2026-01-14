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

require_relative "../../lti_spec_helper"

describe Loaders::SubmissionLtiAssetReportsLoader do
  # Helper method to execute the loader with stubbed fulfill and return results
  def execute_loader(submission_ids:, for_student:, latest:)
    result = {}
    GraphQL::Batch.batch do
      obj = described_class.for(for_student:, latest:)

      allow(obj).to receive(:fulfill) do |submission_id, reports|
        raise "called multiple times for the same submission_id" if result.key?(submission_id)

        result[submission_id] = reports
      end

      obj.perform(submission_ids)
    end
    result
  end

  subject do
    # Ensure the factory objects are created
    [rep1a11, rep1a12, rep1b11, rep2a11, rep2a21]

    execute_loader(submission_ids: [sub1.id, sub2.id], for_student: false, latest: false)
  end

  # These are copied from the Lti::AssetReport model info_for_display test,
  # could DRY up but probably not worth it
  let(:course) { course_factory }
  let(:assignment) { assignment_model(course:) }
  let(:processor1) { lti_asset_processor_model(assignment:) }
  let(:processor2) { lti_asset_processor_model(assignment:) }

  # Student 1
  let(:student1) { student_in_course(course:).user }
  let(:sub1) { assignment.submissions.find_by(user: student1) }
  let(:att1a) { attachment_model(context: student1) }
  let(:asset1a) { lti_asset_model(submission: sub1, attachment: att1a) }
  let(:att1b) { attachment_model(context: student1) }
  let(:asset1b) { lti_asset_model(submission: sub1, attachment: att1b) }

  # Student 2
  let(:student2) { student_in_course(course:).user }
  let(:sub2) { assignment.submissions.find_by(user: student2) }
  let(:att2a) { attachment_model(context: student2) }
  let(:asset2a) { lti_asset_model(submission: sub2, attachment: att2a) }

  # Student 1 (submission 1) reports:
  # Student 1, attachment a (1a), processor I, report type i
  let(:rep1a11) { lti_asset_report_model(asset: asset1a, asset_processor: processor1, report_type: "type_i") }
  let(:rep1a12) { lti_asset_report_model(asset: asset1a, asset_processor: processor1, report_type: "type_ii") }
  let(:rep1b11) { lti_asset_report_model(asset: asset1b, asset_processor: processor1) }

  # Student 2 (submission 2) reports:
  let(:rep2a11) { lti_asset_report_model(asset: asset2a, asset_processor: processor1) }
  let(:rep2a21) { lti_asset_report_model(asset: asset2a, asset_processor: processor2, visible_to_owner: true) }

  it "returns report by submission" do
    expect(subject.keys).to match_array([sub1.id, sub2.id])
    expect(subject[sub1.id]).to match_array([rep1a11, rep1a12, rep1b11])
    expect(subject[sub2.id]).to match_array([rep2a11, rep2a21])
  end

  it "sends empty array if the submission has no active reports" do
    rep2a11.destroy!
    rep2a21.destroy!
    expect(subject[sub2.id]).to be_empty
  end

  it "preloads assets" do
    expect(subject[sub1.id].first.association(:asset).loaded?).to be true
  end

  context "when a processor is deleted" do
    before { processor2.destroy! }

    it "does not include their reports" do
      expect(subject.values.flatten).to match_array([rep1a11, rep1a12, rep1b11, rep2a11])
    end
  end

  it "raises ArgumentError when for_student: true with latest: false" do
    expect do
      GraphQL::Batch.batch do
        described_class.for(for_student: true, latest: false)
      end
    end.to raise_error(ArgumentError)
  end

  # Tests for raw_asset_reports method
  describe "#raw_asset_reports" do
    include LtiSpecHelper

    before do
      # For text_entry scenario
      course_with_student(active_all: true)
      @domain_root_account = @course.root_account

      @assignment_text = assignment_model({ course: @course, submission_types: "online_text_entry" })
      @submission_text = @assignment_text.submit_homework(@student, submission_type: "online_text_entry", body: "Text entry answer")
      # Create a Lti::Asset for the text entry submission (no attachment, but with submission_attempt)
      @asset_text = Lti::Asset.create!(submission_id: @submission_text.id, attachment_id: nil, submission_attempt: @submission_text.attempt)
      @tool = new_valid_external_tool(@course)
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
      result = execute_loader(submission_ids: [third_submission.id, second_submission.id], for_student: true, latest: true)

      expect(result[third_submission.id]).to be_nil
      expect(result[second_submission.id]).to eq([])
    end

    shared_context "group assignment setup for raw_asset_reports" do
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

    describe "with group assignment" do
      include_context "group assignment setup for raw_asset_reports"

      it "includes reports from group mate submissions for students" do
        result = execute_loader(submission_ids: [group1_sub2.id], for_student: true, latest: true)

        expect(result[group1_sub2.id]).to be_a(Array)
        expect(result[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
        expect(result[group1_sub2.id]).not_to include(group2_student1_report, group2_student2_report)
      end

      it "includes reports from group mate submissions for teachers" do
        result = execute_loader(submission_ids: [group1_sub2.id], for_student: false, latest: false)

        expect(result[group1_sub2.id]).to be_a(Array)
        expect(result[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
        expect(result[group1_sub2.id]).not_to include(group2_student1_report, group2_student2_report)
      end

      it "returns reports for multiple group submissions" do
        result = execute_loader(submission_ids: [group1_sub2.id, group2_sub2.id], for_student: true, latest: true)

        expect(result[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
        expect(result[group1_sub2.id]).not_to include(group2_student1_report, group2_student2_report)

        expect(result[group2_sub2.id]).to include(group2_student1_report, group2_student2_report)
        expect(result[group2_sub2.id]).not_to include(group1_student1_report, group1_student2_report)
      end

      it "handles submissions not in groups" do
        result = execute_loader(submission_ids: [@submission.id], for_student: true, latest: true)

        expect(result[@submission.id]).to be_a(Array)
        expect(result[@submission.id]).to include(@apreport1)
      end

      it "filters by visible_to_owner for students" do
        group1_student1_report.update!(visible_to_owner: false)
        group1_student2_report.update!(visible_to_owner: false)

        result = execute_loader(submission_ids: [group1_sub2.id], for_student: true, latest: true)

        expect(result[group1_sub2.id]).to be_nil
      end

      it "does not filter by visible_to_owner for teachers" do
        group1_student1_report.update!(visible_to_owner: false)
        group1_student2_report.update!(visible_to_owner: false)

        result = execute_loader(submission_ids: [group1_sub2.id], for_student: false, latest: false)

        expect(result[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
      end

      it "returns empty array when there are visible reports but none processed for students" do
        group1_student1_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
        group1_student2_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)

        result = execute_loader(submission_ids: [group1_sub2.id], for_student: true, latest: true)

        expect(result[group1_sub2.id]).to eq([])
      end

      it "returns all reports regardless of processing status for teachers" do
        group1_student1_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)
        group1_student2_report.update!(processing_progress: Lti::AssetReport::PROGRESS_PENDING)

        result = execute_loader(submission_ids: [group1_sub2.id], for_student: false, latest: false)

        expect(result[group1_sub2.id]).to include(group1_student1_report, group1_student2_report)
      end
    end

    describe "with last_submission_attempt_only" do
      before do
        # Create a submission with multiple attempts using submission_attempt tracking
        @multi_attempt_assignment = assignment_model(course: @course, submission_types: "online_text_entry")
        @multi_ap = lti_asset_processor_model(tool: @tool, assignment: @multi_attempt_assignment, title: "Multi Attempt AP")

        # Submit first attempt
        @multi_submission = @multi_attempt_assignment.submit_homework(
          @student,
          submission_type: "online_text_entry",
          body: "First attempt"
        )
        expect(@multi_submission.attempt).to eq(1)

        # Find or create asset for first attempt using submission_attempt
        @first_asset = Lti::Asset.find_or_create_by!(
          submission_id: @multi_submission.id,
          submission_attempt: 1
        )
        @first_report = lti_asset_report_model(
          asset_processor: @multi_ap,
          asset: @first_asset,
          title: "First Attempt Report",
          processing_progress: Lti::AssetReport::PROGRESS_PENDING,
          visible_to_owner: true
        )

        # Manually update submission to have a second attempt
        @multi_submission.update!(attempt: 2, body: "Second attempt")

        # Create asset for second attempt
        @second_asset = Lti::Asset.find_or_create_by!(
          submission_id: @multi_submission.id,
          submission_attempt: 2
        )
        @second_report = lti_asset_report_model(
          asset_processor: @multi_ap,
          asset: @second_asset,
          title: "Second Attempt Report",
          processing_progress: Lti::AssetReport::PROGRESS_PROCESSED,
          visible_to_owner: true
        )
        @third_report = lti_asset_report_model(
          asset_processor: @multi_ap,
          asset: @second_asset,
          title: "Second Attempt Report",
          processing_progress: Lti::AssetReport::PROGRESS_PROCESSING,
          visible_to_owner: true,
          report_type: "somedifferenttype"
        )
      end

      it "returns only latest attempt reports when last_submission_attempt_only: true for teachers" do
        result = execute_loader(submission_ids: [@multi_submission.id], for_student: false, latest: true)

        expect(result[@multi_submission.id]).to be_a(Array)
        expect(result[@multi_submission.id]).to include(@second_report, @third_report)
        expect(result[@multi_submission.id]).not_to include(@first_report)
      end

      it "returns all attempt reports when last_submission_attempt_only: false for teachers" do
        result = execute_loader(submission_ids: [@multi_submission.id], for_student: false, latest: false)

        expect(result[@multi_submission.id]).to be_a(Array)
        expect(result[@multi_submission.id]).to include(@first_report, @second_report, @third_report)
      end

      it "students always see only latest attempt, and only processed reports, regardless of last_submission_attempt_only" do
        # for_student implies last_submission_attempt_only
        result = execute_loader(submission_ids: [@multi_submission.id], for_student: true, latest: true)

        expect(result[@multi_submission.id]).to be_a(Array)
        expect(result[@multi_submission.id]).to include(@second_report)
        expect(result[@multi_submission.id]).not_to include(@first_report)
        expect(result[@multi_submission.id]).not_to include(@third_report)
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

        result = execute_loader(submission_ids: [text_submission.id], for_student: true, latest: true)

        expect(result[text_submission.id]).to be_nil
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

        result = execute_loader(submission_ids: [file_submission.id], for_student: true, latest: true)

        expect(result[file_submission.id]).not_to be_nil
        expect(result[file_submission.id].length).to eq(1)
        expect(result[file_submission.id].first[:title]).to eq("String Comparison Report")
      end
    end
  end

  describe "sorting by asset creation time" do
    include LtiSpecHelper

    before do
      course_with_student(active_all: true)
      @assignment = assignment_model(course: @course)
      @tool = new_valid_external_tool(@course)
      @processor = lti_asset_processor_model(tool: @tool, assignment: @assignment)
    end

    it "returns reports sorted by asset.created_at DESC (newest first)" do
      # Create assets with staggered timestamps
      oldest_asset = lti_asset_model(submission: @assignment.submissions.find_by(user: @student))
      oldest_asset.update!(created_at: 3.days.ago)
      oldest_report = lti_asset_report_model(
        asset: oldest_asset,
        asset_processor: @processor
      )

      middle_asset = lti_asset_model(submission: @assignment.submissions.find_by(user: @student))
      middle_asset.update!(created_at: 2.days.ago)
      middle_report = lti_asset_report_model(
        asset: middle_asset,
        asset_processor: @processor
      )

      newest_asset = lti_asset_model(submission: @assignment.submissions.find_by(user: @student))
      newest_asset.update!(created_at: 1.day.ago)
      newest_report = lti_asset_report_model(
        asset: newest_asset,
        asset_processor: @processor
      )

      result = execute_loader(
        submission_ids: [@assignment.submissions.find_by(user: @student).id],
        for_student: false,
        latest: false
      )

      submission_id = @assignment.submissions.find_by(user: @student).id
      # Should be ordered newest first
      expect(result[submission_id]).to eq([newest_report, middle_report, oldest_report])
    end

    it "sorts correctly when for_student: true" do
      submission = @assignment.submissions.find_by(user: @student)

      # Create assets in reverse chronological order
      older_asset = lti_asset_model(submission:)
      older_asset.update!(created_at: 2.days.ago)
      older_report = lti_asset_report_model(
        asset: older_asset,
        asset_processor: @processor,
        visible_to_owner: true,
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED
      )

      newer_asset = lti_asset_model(submission:)
      newer_asset.update!(created_at: 1.day.ago)
      newer_report = lti_asset_report_model(
        asset: newer_asset,
        asset_processor: @processor,
        visible_to_owner: true,
        processing_progress: Lti::AssetReport::PROGRESS_PROCESSED
      )

      result = execute_loader(
        submission_ids: [submission.id],
        for_student: true,
        latest: true
      )

      # Should be sorted newest first even for students
      expect(result[submission.id]).to eq([newer_report, older_report])
    end

    it "handles assets with same creation time using stable sort" do
      submission = @assignment.submissions.find_by(user: @student)
      same_time = 1.day.ago

      # Create multiple assets with the same timestamp
      asset1 = lti_asset_model(submission:)
      asset1.update!(created_at: same_time)
      report1 = lti_asset_report_model(asset: asset1, asset_processor: @processor)

      asset2 = lti_asset_model(submission:)
      asset2.update!(created_at: same_time)
      report2 = lti_asset_report_model(asset: asset2, asset_processor: @processor)

      asset3 = lti_asset_model(submission:)
      asset3.update!(created_at: same_time)
      report3 = lti_asset_report_model(asset: asset3, asset_processor: @processor)

      result = execute_loader(
        submission_ids: [submission.id],
        for_student: false,
        latest: false
      )

      # All reports should be present
      expect(result[submission.id]).to match_array([report1, report2, report3])
      # They should all have the same created_at
      expect(result[submission.id].map { |r| r.asset.created_at }).to all(eq(same_time))
    end

    it "handles very old assets appearing before recent ones" do
      submission = @assignment.submissions.find_by(user: @student)

      # Create very old asset
      old_asset = lti_asset_model(submission:)
      old_asset.update!(created_at: 1.year.ago)
      old_report = lti_asset_report_model(
        asset: old_asset,
        asset_processor: @processor
      )

      # Create recent asset
      recent_asset = lti_asset_model(submission:)
      recent_asset.update!(created_at: 1.hour.ago)
      recent_report = lti_asset_report_model(
        asset: recent_asset,
        asset_processor: @processor
      )

      result = execute_loader(
        submission_ids: [submission.id],
        for_student: false,
        latest: false
      )

      # Recent report should come first despite old report existing
      expect(result[submission.id]).to eq([recent_report, old_report])
    end
  end
end
