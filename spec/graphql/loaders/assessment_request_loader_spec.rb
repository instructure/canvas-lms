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

describe Loaders::AssessmentRequestLoader do
  before(:once) do
    course_with_teacher(active_all: true)
    @assignment = @course.assignments.create!(
      title: "Peer Review Assignment",
      peer_reviews: true,
      submission_types: "online_text_entry"
    )

    @student1 = student_in_course(active_all: true, course: @course).user
    @student2 = student_in_course(active_all: true, course: @course).user
    @student3 = student_in_course(active_all: true, course: @course).user

    @submission2 = @assignment.submit_homework(@student2, body: "Student 2 submission")
    @submission3 = @assignment.submit_homework(@student3, body: "Student 3 submission")

    @assessment_request1 = @assignment.assign_peer_review(@student1, @student2)
    @assessment_request2 = @assignment.assign_peer_review(@student1, @student3)
  end

  describe "order_by_id parameter" do
    it "returns assessment requests without ordering when order_by_id is false" do
      GraphQL::Batch.batch do
        loader = Loaders::AssessmentRequestLoader.for(current_user: @student1, order_by_id: false)
        loader.load(@assignment).then do |requests|
          expect(requests).to match_array([@assessment_request1, @assessment_request2])
          expect(requests.length).to eq(2)
        end
      end
    end

    it "returns assessment requests ordered by id when order_by_id is true" do
      GraphQL::Batch.batch do
        loader = Loaders::AssessmentRequestLoader.for(current_user: @student1, order_by_id: true)
        loader.load(@assignment).then do |requests|
          expect(requests.length).to eq(2)
          expect(requests.map(&:id)).to eq(requests.map(&:id).sort)
          expect(requests.first.id).to be < requests.second.id
        end
      end
    end

    it "defaults to no ordering when order_by_id is not specified" do
      GraphQL::Batch.batch do
        loader = Loaders::AssessmentRequestLoader.for(current_user: @student1)
        loader.load(@assignment).then do |requests|
          expect(requests).to match_array([@assessment_request1, @assessment_request2])
          expect(requests.length).to eq(2)
        end
      end
    end

    it "maintains consistent ordering across multiple loads when order_by_id is true" do
      first_load_result = nil
      second_load_result = nil

      GraphQL::Batch.batch do
        loader = Loaders::AssessmentRequestLoader.for(current_user: @student1, order_by_id: true)
        loader.load(@assignment).then do |requests|
          first_load_result = requests.map(&:id)
        end
      end

      GraphQL::Batch.batch do
        loader = Loaders::AssessmentRequestLoader.for(current_user: @student1, order_by_id: true)
        loader.load(@assignment).then do |requests|
          second_load_result = requests.map(&:id)
        end
      end

      expect(first_load_result).to eq(second_load_result)
    end
  end

  describe "filtering and preloading" do
    it "only returns assessment requests for the current user" do
      student_in_course(active_all: true, course: @course).user

      GraphQL::Batch.batch do
        loader = Loaders::AssessmentRequestLoader.for(current_user: @student1, order_by_id: true)
        loader.load(@assignment).then do |requests|
          expect(requests.map(&:assessor_id).uniq).to eq([@student1.id])
        end
      end
    end

    it "preloads associations to prevent N+1 queries" do
      GraphQL::Batch.batch do
        loader = Loaders::AssessmentRequestLoader.for(current_user: @student1, order_by_id: true)
        loader.load(@assignment).then do |requests|
          # Verify associations are preloaded by checking association cache
          requests.each do |request|
            expect(request.association(:asset).loaded?).to be true
            expect(request.association(:submission_comments).loaded?).to be true
            expect(request.association(:rubric_assessment).loaded?).to be true
          end
        end
      end
    end

    it "filters out non-participating students" do
      # Create an assessment request but then remove the student from the course
      removed_student = student_in_course(active_all: true, course: @course).user
      @assignment.submit_homework(removed_student, body: "Removed student submission")
      assessment_request3 = @assignment.assign_peer_review(@student1, removed_student)

      enrollment = @course.enrollments.find_by(user: removed_student)
      enrollment.destroy

      GraphQL::Batch.batch do
        loader = Loaders::AssessmentRequestLoader.for(current_user: @student1, order_by_id: true)
        loader.load(@assignment).then do |requests|
          expect(requests).not_to include(assessment_request3)
          expect(requests).to match_array([@assessment_request1, @assessment_request2])
        end
      end
    end
  end
end
