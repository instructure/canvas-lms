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

require_relative "../../spec_helper"

describe Loaders::SubmissionLtiAssetReportsStudentLoader do
  subject do
    obj = described_class.new
    result = {}

    allow(obj).to receive(:fulfill) do |submission_id, reports|
      raise "called multiple times for the same submission_id" if result.key?(submission_id)

      result[submission_id] = reports
    end

    obj.perform([sub1.id, sub2.id])

    result
  end

  # Test data setup similar to the reference spec
  let(:course) { course_factory }
  let(:assignment) { assignment_model(course:) }

  # Student 1
  let(:student1) { student_in_course(course:).user }
  let(:sub1) { assignment.submissions.find_by(user: student1) }

  # Student 2
  let(:student2) { student_in_course(course:).user }
  let(:sub2) { assignment.submissions.find_by(user: student2) }

  describe "#perform" do
    before do
      allow_any_instance_of(described_class).to receive(:raw_asset_reports).with(submission: sub1).and_return([1, 2])
      allow_any_instance_of(described_class).to receive(:raw_asset_reports).with(submission: sub2).and_return([3, 4])
    end

    it "returns report by submission using student helper" do
      expect(subject.keys).to match_array([sub1.id, sub2.id])
      expect(subject[sub1.id]).to match_array([1, 2])
      expect(subject[sub2.id]).to match_array([3, 4])
    end

    it "handles empty submission ID array" do
      obj = described_class.new
      result = {}

      allow(obj).to receive(:fulfill) do |submission_id, reports|
        result[submission_id] = reports
      end

      obj.perform([])

      expect(result).to be_empty
    end

    it "returns nil for non-existent submissions" do
      non_existent_id = Submission.maximum(:id).to_i + 1

      obj = described_class.new
      result = {}

      allow(obj).to receive(:fulfill) do |submission_id, reports|
        result[submission_id] = reports
      end

      obj.perform([non_existent_id])

      expect(result[non_existent_id]).to be_nil
    end
  end
end
