# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require "spec_helper"

RSpec.describe PeerReview::AllocationRuleConverterService do
  let(:course) { course_model }
  let(:assignment) { assignment_model(course:, peer_reviews: true) }
  let(:assessor) { user_model }
  let(:assessee) { user_model }

  before do
    course.enroll_student(assessor, enrollment_state: "active")
    course.enroll_student(assessee, enrollment_state: "active")
  end

  describe "#call" do
    context "when resource is invalid" do
      it "raises ArgumentError for nil resource" do
        service = described_class.new(nil)
        expect { service.call }.to raise_error(ArgumentError, "Resource must be an AssessmentRequest or AllocationRule")
      end

      it "raises ArgumentError for Assignment resource" do
        service = described_class.new(assignment)
        expect { service.call }.to raise_error(ArgumentError, "Resource must be an AssessmentRequest or AllocationRule")
      end

      it "raises ArgumentError for String resource" do
        service = described_class.new("invalid")
        expect { service.call }.to raise_error(ArgumentError, "Resource must be an AssessmentRequest or AllocationRule")
      end

      it "raises ArgumentError for Hash resource" do
        service = described_class.new({ id: 1 })
        expect { service.call }.to raise_error(ArgumentError, "Resource must be an AssessmentRequest or AllocationRule")
      end
    end
  end

  describe "converting AssessmentRequest to AllocationRule" do
    let(:assessment_request) { assignment.assign_peer_review(assessor, assessee) }

    context "successful conversion" do
      it "creates an AllocationRule" do
        service = described_class.new(assessment_request)
        expect { service.call }.to change(AllocationRule, :count).by(1)
      end

      it "sets correct attributes on AllocationRule" do
        service = described_class.new(assessment_request)
        result = service.call

        expect(result).to be_a(AllocationRule)
        expect(result.assessor_id).to eq(assessor.id)
        expect(result.assessee_id).to eq(assessee.id)
        expect(result.assignment_id).to eq(assignment.id)
        expect(result.course_id).to eq(course.id)
        expect(result.must_review).to be(true)
        expect(result.review_permitted).to be(true)
        expect(result.applies_to_assessor).to be(true)
      end

      it "deletes the AssessmentRequest after successful conversion" do
        service = described_class.new(assessment_request)
        service.call

        expect { assessment_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "returns the created AllocationRule" do
        service = described_class.new(assessment_request)
        result = service.call

        expect(result).to be_persisted
        expect(result).to be_a(AllocationRule)
      end
    end

    context "when AssessmentRequest is completed" do
      let(:completed_assessment_request) do
        ar = assignment.assign_peer_review(assessor, assessee)
        ar.complete!
        ar
      end

      it "does not create an AllocationRule" do
        service = described_class.new(completed_assessment_request)
        expect { service.call }.not_to change(AllocationRule, :count)
      end

      it "returns nil" do
        service = described_class.new(completed_assessment_request)
        result = service.call

        expect(result).to be_nil
      end

      it "does not delete the completed AssessmentRequest" do
        service = described_class.new(completed_assessment_request)
        service.call

        expect(completed_assessment_request.reload).to be_persisted
      end
    end

    context "when assignment is invalid" do
      context "when AssessmentRequest has no submission" do
        let(:assessment_request_without_submission) do
          ar = assignment.assign_peer_review(assessor, assessee)
          # Mock the submission method to return nil
          allow(ar).to receive(:submission).and_return(nil)
          ar
        end

        it "raises ArgumentError" do
          service = described_class.new(assessment_request_without_submission)
          expect { service.call }.to raise_error(ArgumentError, "Assignment is required")
        end

        it "does not create an AllocationRule" do
          service = described_class.new(assessment_request_without_submission)
          expect do
            service.call
          rescue ArgumentError
            nil
          end.not_to change(AllocationRule, :count)
        end
      end

      context "when assignment does not have peer reviews enabled" do
        let(:assignment_with_peer_reviews) { assignment_model(course:, peer_reviews: true) }
        let(:assessment_request_without_peer_reviews) do
          # Create assessment request while peer reviews are enabled
          ar = assignment_with_peer_reviews.assign_peer_review(assessor, assessee)
          # Then disable peer reviews on the assignment
          assignment_with_peer_reviews.update!(peer_reviews: false)
          ar
        end

        it "raises ArgumentError" do
          service = described_class.new(assessment_request_without_peer_reviews)
          expect { service.call }.to raise_error(ArgumentError, "Assignment must have peer reviews enabled")
        end

        it "does not create an AllocationRule" do
          service = described_class.new(assessment_request_without_peer_reviews)
          expect do
            service.call
          rescue ArgumentError
            nil
          end.not_to change(AllocationRule, :count)
        end
      end
    end

    context "when AllocationRule validation fails" do
      context "due to inactive assessor enrollment" do
        before do
          # Make assessor's enrollment inactive
          course.enrollments.find_by(user: assessor).deactivate
        end

        it "does not create an AllocationRule" do
          service = described_class.new(assessment_request)
          expect { service.call }.not_to change(AllocationRule, :count)
        end

        it "logs the validation failure" do
          service = described_class.new(assessment_request)
          expect(Rails.logger).to receive(:info).with(/Skipped converting AssessmentRequest.*assessor.*must have an active enrollment/)

          service.call
        end

        it "deletes the AssessmentRequest despite validation failure" do
          service = described_class.new(assessment_request)
          service.call

          expect { assessment_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "returns nil" do
          service = described_class.new(assessment_request)
          result = service.call

          expect(result).to be_nil
        end
      end

      context "due to inactive assessee enrollment" do
        before do
          # Make assessee's enrollment inactive
          course.enrollments.find_by(user: assessee).deactivate
        end

        it "does not create an AllocationRule" do
          service = described_class.new(assessment_request)
          expect { service.call }.not_to change(AllocationRule, :count)
        end

        it "logs the validation failure" do
          service = described_class.new(assessment_request)
          expect(Rails.logger).to receive(:info).with(/Skipped converting AssessmentRequest.*assessee.*must have an active enrollment/)

          service.call
        end

        it "deletes the AssessmentRequest despite validation failure" do
          service = described_class.new(assessment_request)
          service.call

          expect { assessment_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "due to duplicate AllocationRule" do
        before do
          # Create a conflicting AllocationRule
          AllocationRule.create!(
            assessor:,
            assessee:,
            assignment:,
            course:,
            must_review: true,
            review_permitted: true
          )
        end

        it "does not create a duplicate AllocationRule" do
          service = described_class.new(assessment_request)
          expect { service.call }.not_to change(AllocationRule, :count)
        end

        it "logs the conflict" do
          service = described_class.new(assessment_request)
          expect(Rails.logger).to receive(:info).with(/Skipped converting AssessmentRequest.*conflicts with rule/)

          service.call
        end

        it "deletes the AssessmentRequest despite conflict" do
          service = described_class.new(assessment_request)
          service.call

          expect { assessment_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "returns nil" do
          service = described_class.new(assessment_request)
          result = service.call

          expect(result).to be_nil
        end
      end

      context "due to lack of assignment visibility" do
        let(:section1) { course.course_sections.create!(name: "Section 1") }
        let(:section2) { course.course_sections.create!(name: "Section 2") }

        before do
          # Re-enroll students in different sections
          course.enrollments.find_by(user: assessor).destroy
          course.enrollments.find_by(user: assessee).destroy
          course.enroll_student(assessor, section: section1, enrollment_state: "active")
          course.enroll_student(assessee, section: section2, enrollment_state: "active")

          # Limit assignment visibility to section1 only
          assignment.update!(only_visible_to_overrides: true)
          assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: section1.id)
        end

        it "does not create an AllocationRule when assessee has no visibility" do
          service = described_class.new(assessment_request)
          expect { service.call }.not_to change(AllocationRule, :count)
        end

        it "logs the visibility issue" do
          service = described_class.new(assessment_request)
          expect(Rails.logger).to receive(:info).with(/Skipped converting AssessmentRequest.*must be a student with visibility/)

          service.call
        end

        it "deletes the AssessmentRequest" do
          service = described_class.new(assessment_request)
          service.call

          expect { assessment_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
