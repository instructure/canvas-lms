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

describe Loaders::SubmissionLtiAssetReportsLoader do
  subject do
    # Ensure the factory objects are created
    [rep1a11, rep1a12, rep1b11, rep2a11, rep2a21]

    result = {}
    GraphQL::Batch.batch do
      obj = described_class.for(for_student: false, latest: false)

      allow(obj).to receive(:fulfill) do |submission_id, reports|
        raise "called multiple times for the same submission_id" if result.key?(submission_id)

        result[submission_id] = reports
      end

      obj.perform([sub1.id, sub2.id])
    end
    result
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

  context "with group assignments" do
    subject do
      # Ensure let's runs
      [group1_sub1, group1_sub2, group2_sub1, group2_sub2, group3_sub1, group3_sub2]
      [group1_student1_rep1, group2_student1_rep1, group3_student1_rep1]

      result = {}
      GraphQL::Batch.batch do
        obj = described_class.for(for_student: false, latest: false)

        allow(obj).to receive(:fulfill) do |submission_id, reports|
          raise "called multiple times for the same submission_id" if result.key?(submission_id)

          result[submission_id] = reports
        end

        obj.perform([group1_sub2.id, group2_sub2.id])
      end
      result
    end

    # Have three groups and two students and 1 report for student1 in each group

    let(:group_category) { course.group_categories.create!(name: "Group Category") }
    let(:group1) { group_category.groups.create!(name: "Test Group 1", context: course) }
    let(:group2) { group_category.groups.create!(name: "Test Group 2", context: course) }
    let(:group3) { group_category.groups.create!(name: "Test Group 3", context: course) }

    let(:group1_student1) { student_in_course(course:).user }
    let(:group1_student2) { student_in_course(course:).user }
    let(:group2_student1) { student_in_course(course:).user }
    let(:group2_student2) { student_in_course(course:).user }
    let(:group3_student1) { student_in_course(course:).user }
    let(:group3_student2) { student_in_course(course:).user }

    let(:assignment) { assignment_model(course:, group_category:) }
    let(:asset_processor) { lti_asset_processor_model(assignment:) }

    let(:group1_sub1) do
      group1.add_user(group1_student1)
      assignment.submissions.find_by(user: group1_student1).tap { |s| s.update!(group: group1) }
    end
    let(:group1_sub2) do
      group1.add_user(group1_student2)
      assignment.submissions.find_by(user: group1_student2).tap { |s| s.update!(group: group1) }
    end
    let(:group2_sub1) do
      group2.add_user(group2_student1)
      assignment.submissions.find_by(user: group2_student1).tap { |s| s.update!(group: group2) }
    end
    let(:group2_sub2) do
      group2.add_user(group2_student2)
      assignment.submissions.find_by(user: group2_student2).tap { |s| s.update!(group: group2) }
    end
    let(:group3_sub1) do
      group3.add_user(group3_student1)
      assignment.submissions.find_by(user: group3_student1).tap { |s| s.update!(group: group3) }
    end
    let(:group3_sub2) do
      group3.add_user(group3_student2)
      assignment.submissions.find_by(user: group3_student2).tap { |s| s.update!(group: group3) }
    end

    let(:group1_student1_asset1) { lti_asset_model(submission: group1_sub1, attachment: attachment_model(context: group1_student1)) }
    let(:group2_student1_asset1) { lti_asset_model(submission: group2_sub1, attachment: attachment_model(context: group2_student1)) }
    let(:group3_student1_asset1) { lti_asset_model(submission: group3_sub1, attachment: attachment_model(context: group3_student1)) }

    let(:group1_student1_rep1) { lti_asset_report_model(asset: group1_student1_asset1, asset_processor:, report_type: "group_type_1") }
    let(:group2_student1_rep1) { lti_asset_report_model(asset: group2_student1_asset1, asset_processor:, report_type: "group_type_1") }
    let(:group3_student1_rep1) { lti_asset_report_model(asset: group3_student1_asset1, asset_processor:, report_type: "group_type_1") }

    it "includes reports for mate submissions in the same group" do
      result = subject
      expect(result.keys).to match_array([group1_sub2.id, group2_sub2.id])
      # Each submission should get all reports from the group
      expect(result[group1_sub2.id]).to match_array([group1_student1_rep1])
      expect(result[group2_sub2.id]).to match_array([group2_student1_rep1])
    end

    it "doesn't include reports for different group" do
      # Test that we don't get duplicate reports
      all_reports = subject.values.flatten
      expect(all_reports).not_to include(group3_student1_rep1)
    end
  end

  context "when used for student access" do
    subject do
      result = {}
      GraphQL::Batch.batch do
        obj = described_class.for(for_student: true, latest: true)

        allow(obj).to receive(:fulfill) do |submission_id, reports|
          raise "called multiple times for the same submission_id" if result.key?(submission_id)

          result[submission_id] = reports
        end

        obj.perform([1, 2])
      end
      result
    end

    before do
      allow_any_instance_of(described_class).to receive(:raw_asset_reports)
        .with(submission_ids: [1, 2], for_student: true, last_submission_attempt_only: true)
        .and_return({ 1 => [1, 2], 2 => [3, 4] })
    end

    it "returns report by submission using student filtering" do
      expect(subject.keys).to match_array([1, 2])
      expect(subject[1]).to match_array([1, 2])
      expect(subject[2]).to match_array([3, 4])
    end

    it "handles empty submission ID array" do
      result = {}

      allow_any_instance_of(described_class).to receive(:raw_asset_reports)
        .with(submission_ids: [], for_student: true, last_submission_attempt_only: true)
        .and_return({})

      GraphQL::Batch.batch do
        obj = described_class.for(for_student: true, latest: true)

        allow(obj).to receive(:fulfill) do |submission_id, reports|
          result[submission_id] = reports
        end

        obj.perform([])
      end

      expect(result).to be_empty
    end

    it "raises ArgumentError when for_student: true with latest: false" do
      expect do
        GraphQL::Batch.batch do
          described_class.for(for_student: true, latest: false)
        end
      end.to raise_error(ArgumentError)
    end
  end

  context "when used for teacher access with latest: true" do
    subject do
      result = {}
      GraphQL::Batch.batch do
        obj = described_class.for(for_student: false, latest: true)

        allow(obj).to receive(:fulfill) do |submission_id, reports|
          raise "called multiple times for the same submission_id" if result.key?(submission_id)

          result[submission_id] = reports
        end

        obj.perform([sub1.id, sub2.id])
      end
      result
    end

    before do
      allow_any_instance_of(described_class).to receive(:raw_asset_reports)
        .with(submission_ids: [sub1.id, sub2.id], for_student: false, last_submission_attempt_only: true)
        .and_return({ sub1.id => [rep1a11], sub2.id => [rep2a11] })
    end

    it "returns only latest attempt reports for teachers when latest: true" do
      expect(subject.keys).to match_array([sub1.id, sub2.id])
      expect(subject[sub1.id]).to match_array([rep1a11])
      expect(subject[sub2.id]).to match_array([rep2a11])
    end
  end
end
