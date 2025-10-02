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

require "spec_helper"

RSpec.describe PeerReview::DateOverriderService do
  let(:course) { course_model(name: "Test Course") }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
  let(:overrides) { [] }

  let(:service) do
    described_class.new(
      peer_review_sub_assignment:,
      overrides:
    )
  end

  before do
    course.enable_feature!(:peer_review_grading)
  end

  describe "#initialize" do
    it "sets the instance variables correctly" do
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@assignment)).to eq(parent_assignment)
      expect(service.instance_variable_get(:@overrides)).to eq(overrides)
    end

    it "defaults overrides to empty array when nil" do
      service = described_class.new(peer_review_sub_assignment:)
      expect(service.instance_variable_get(:@overrides)).to eq([])
    end

    it "handles nil peer_review_sub_assignment" do
      service = described_class.new(peer_review_sub_assignment: nil)
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@assignment)).to be_nil
    end
  end

  describe "#format_overrides" do
    context "when overrides are in standard format" do
      it "returns overrides unchanged" do
        overrides = [
          { set_type: "CourseSection", set_id: 1, due_at: 1.week.from_now },
          { set_type: "ADHOC", student_ids: [1, 2, 3], due_at: 2.weeks.from_now }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq(overrides)
      end
    end

    context "when overrides are in REST API format" do
      it "converts course_section_id to set_type and set_id" do
        overrides = [
          { course_section_id: 123, due_at: 1.week.from_now }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "CourseSection", set_id: 123, due_at: overrides[0][:due_at] }
                                ])
      end

      it "converts group_id to set_type and set_id" do
        overrides = [
          { group_id: 456, due_at: 1.week.from_now }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "Group", set_id: 456, due_at: overrides[0][:due_at] }
                                ])
      end

      it "converts course_id to set_type and set_id" do
        overrides = [
          { course_id: 789, due_at: 1.week.from_now }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "Course", set_id: 789, due_at: overrides[0][:due_at] }
                                ])
      end

      it "converts student_ids to ADHOC set_type" do
        overrides = [
          { student_ids: [1, 2, 3], due_at: 1.week.from_now }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "ADHOC", student_ids: [1, 2, 3], due_at: overrides[0][:due_at] }
                                ])
      end

      it "handles student_ids as strings and converts to integers" do
        overrides = [
          { student_ids: %w[10 20 30], due_at: 1.week.from_now }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "ADHOC", student_ids: [10, 20, 30], due_at: overrides[0][:due_at] }
                                ])
      end

      it "preserves id when present" do
        overrides = [
          { id: "42", course_section_id: 123, due_at: 1.week.from_now }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { id: 42, set_type: "CourseSection", set_id: 123, due_at: overrides[0][:due_at] }
                                ])
      end

      it "preserves all date fields" do
        due_at = 1.week.from_now
        unlock_at = 1.day.from_now
        lock_at = 2.weeks.from_now

        overrides = [
          { course_section_id: 123, due_at:, unlock_at:, lock_at: }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "CourseSection", set_id: 123, due_at:, unlock_at:, lock_at: }
                                ])
      end

      it "preserves unassign_item flag" do
        overrides = [
          { course_section_id: 123, unassign_item: true }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "CourseSection", set_id: 123, unassign_item: true }
                                ])
      end

      it "does not include unassign_item when not present" do
        overrides = [
          { course_section_id: 345, due_at: 1.week.from_now }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "CourseSection", set_id: 345, due_at: overrides[0][:due_at] }
                                ])
      end
    end

    context "with mixed format overrides" do
      it "formats only overrides that need formatting" do
        due_at1 = 1.week.from_now
        due_at2 = 2.weeks.from_now

        overrides = [
          { set_type: "CourseSection", set_id: 1, due_at: due_at1 },
          { course_section_id: 2, due_at: due_at2 }
        ]
        service = described_class.new(peer_review_sub_assignment:, overrides:)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([
                                  { set_type: "CourseSection", set_id: 1, due_at: due_at1 },
                                  { set_type: "CourseSection", set_id: 2, due_at: due_at2 }
                                ])
      end
    end

    context "with empty or nil overrides" do
      it "handles empty array" do
        service = described_class.new(peer_review_sub_assignment:, overrides: [])
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([])
      end

      it "handles nil overrides" do
        service = described_class.new(peer_review_sub_assignment:, overrides: nil)
        formatted = service.instance_variable_get(:@overrides)

        expect(formatted).to eq([])
      end
    end
  end

  describe "#needs_formatting?" do
    it "returns true when course_section_id is present" do
      service = described_class.new(peer_review_sub_assignment:)
      override = { course_section_id: 123 }

      expect(service.send(:needs_formatting?, override)).to be true
    end

    it "returns true when group_id is present" do
      service = described_class.new(peer_review_sub_assignment:)
      override = { group_id: 456 }

      expect(service.send(:needs_formatting?, override)).to be true
    end

    it "returns true when course_id is present" do
      service = described_class.new(peer_review_sub_assignment:)
      override = { course_id: 789 }

      expect(service.send(:needs_formatting?, override)).to be true
    end

    it "returns true when student_ids is present without set_type" do
      service = described_class.new(peer_review_sub_assignment:)
      override = { student_ids: [1, 2, 3] }

      expect(service.send(:needs_formatting?, override)).to be true
    end

    it "returns false when student_ids has set_type" do
      service = described_class.new(peer_review_sub_assignment:)
      override = { student_ids: [1, 2, 3], set_type: "ADHOC" }

      expect(service.send(:needs_formatting?, override)).to be false
    end

    it "returns false when override is in standard format" do
      service = described_class.new(peer_review_sub_assignment:)
      override = { set_type: "CourseSection", set_id: 123 }

      expect(service.send(:needs_formatting?, override)).to be false
    end
  end

  describe "#format_api_override" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    context "with CourseSection override" do
      it "converts course_section_id to set_type and set_id" do
        override = { course_section_id: 123, due_at: 1.week.from_now }
        result = service.send(:format_api_override, override)

        expect(result).to include(
          set_type: "CourseSection",
          set_id: 123,
          due_at: override[:due_at]
        )
      end
    end

    context "with Group override" do
      it "converts group_id to set_type and set_id" do
        override = { group_id: 456, due_at: 1.week.from_now }
        result = service.send(:format_api_override, override)

        expect(result).to include(
          set_type: "Group",
          set_id: 456,
          due_at: override[:due_at]
        )
      end
    end

    context "with Course override" do
      it "converts course_id to set_type and set_id" do
        override = { course_id: 789, due_at: 1.week.from_now }
        result = service.send(:format_api_override, override)

        expect(result).to include(
          set_type: "Course",
          set_id: 789,
          due_at: override[:due_at]
        )
      end
    end

    context "with ADHOC override" do
      it "converts student_ids to set_type and student_ids array" do
        override = { student_ids: [10, 20, 30], due_at: 1.week.from_now }
        result = service.send(:format_api_override, override)

        expect(result).to include(
          set_type: "ADHOC",
          student_ids: [10, 20, 30],
          due_at: override[:due_at]
        )
      end

      it "converts student_ids strings to integers" do
        override = { student_ids: ["100", "200"], due_at: 1.week.from_now }
        result = service.send(:format_api_override, override)

        expect(result).to include(
          set_type: "ADHOC",
          student_ids: [100, 200]
        )
      end
    end

    context "with id field" do
      it "includes id as integer" do
        override = { id: "42", course_section_id: 123 }
        result = service.send(:format_api_override, override)

        expect(result[:id]).to eq(42)
      end

      it "does not include id when not present" do
        override = { course_section_id: 123 }
        result = service.send(:format_api_override, override)

        expect(result).not_to have_key(:id)
      end
    end

    context "with date fields" do
      it "includes due_at when present" do
        due_at = 1.week.from_now
        override = { course_section_id: 123, due_at: }
        result = service.send(:format_api_override, override)

        expect(result[:due_at]).to eq(due_at)
      end

      it "includes unlock_at when present" do
        unlock_at = 1.day.from_now
        override = { course_section_id: 123, unlock_at: }
        result = service.send(:format_api_override, override)

        expect(result[:unlock_at]).to eq(unlock_at)
      end

      it "includes lock_at when present" do
        lock_at = 2.weeks.from_now
        override = { course_section_id: 123, lock_at: }
        result = service.send(:format_api_override, override)

        expect(result[:lock_at]).to eq(lock_at)
      end

      it "includes date fields with nil values" do
        override = { course_section_id: 123, due_at: nil, unlock_at: nil, lock_at: nil }
        result = service.send(:format_api_override, override)

        expect(result).to have_key(:due_at)
        expect(result).to have_key(:unlock_at)
        expect(result).to have_key(:lock_at)
        expect(result[:due_at]).to be_nil
      end

      it "excludes date fields when not present in override" do
        override = { course_section_id: 123 }
        result = service.send(:format_api_override, override)

        expect(result).not_to have_key(:due_at)
        expect(result).not_to have_key(:unlock_at)
        expect(result).not_to have_key(:lock_at)
      end
    end

    context "with unassign_item field" do
      it "includes unassign_item when true" do
        override = { course_section_id: 123, unassign_item: true }
        result = service.send(:format_api_override, override)

        expect(result[:unassign_item]).to be true
      end

      it "includes unassign_item when false" do
        override = { course_section_id: 123, unassign_item: false }
        result = service.send(:format_api_override, override)

        expect(result[:unassign_item]).to be false
      end

      it "does not include unassign_item when not present" do
        override = { course_section_id: 123 }
        result = service.send(:format_api_override, override)

        expect(result).not_to have_key(:unassign_item)
      end
    end
  end

  describe "#call" do
    before do
      allow(service).to receive(:run_validations)
      allow(service).to receive(:create_or_update_peer_review_overrides)
    end

    it "calls run_validations" do
      expect(service).to receive(:run_validations)
      service.call
    end

    it "calls create_or_update_peer_review_overrides" do
      expect(service).to receive(:create_or_update_peer_review_overrides)
      service.call
    end
  end

  describe "#run_validations" do
    it "runs all required validations" do
      expect(service).to receive(:validate_parent_assignment).with(parent_assignment)
      expect(service).to receive(:validate_feature_enabled).with(parent_assignment)
      expect(service).to receive(:validate_peer_reviews_enabled).with(parent_assignment)
      expect(service).to receive(:validate_peer_review_sub_assignment_exists).with(parent_assignment)

      service.send(:run_validations)
    end
  end

  describe "validations" do
    context "when parent assignment is invalid" do
      let(:parent_assignment) { nil }

      it "raises InvalidParentAssignmentError" do
        service = described_class.new(peer_review_sub_assignment: nil)
        expect { service.call }.to raise_error(PeerReview::InvalidParentAssignmentError)
      end
    end

    context "when feature is disabled" do
      before do
        parent_assignment.context.disable_feature!(:peer_review_grading)
      end

      it "raises FeatureDisabledError" do
        service = described_class.new(peer_review_sub_assignment:)
        expect { service.call }.to raise_error(PeerReview::FeatureDisabledError)
      end
    end

    context "when peer reviews are not enabled" do
      before do
        parent_assignment.peer_reviews = false
        parent_assignment.save!
      end

      it "raises PeerReviewsNotEnabledError" do
        service = described_class.new(peer_review_sub_assignment:)
        expect { service.call }.to raise_error(PeerReview::PeerReviewsNotEnabledError)
      end
    end

    context "when peer review sub assignment does not exist" do
      before do
        allow(parent_assignment).to receive(:peer_review_sub_assignment).and_return(nil)
      end

      it "raises SubAssignmentNotExistError" do
        service = described_class.new(peer_review_sub_assignment:)
        expect { service.call }.to raise_error(PeerReview::SubAssignmentNotExistError)
      end
    end
  end

  describe "#create_or_update_peer_review_overrides" do
    let(:existing_section1) { add_section("Existing Section 1", course:) }
    let(:existing_section2) { add_section("Existing Section 2", course:) }
    let(:existing_section3) { add_section("Existing Section 3", course:) }

    let(:existing_override1) { assignment_override_model(assignment: peer_review_sub_assignment, set: existing_section1) }
    let(:existing_override2) { assignment_override_model(assignment: peer_review_sub_assignment, set: existing_section2) }
    let(:existing_override3) { assignment_override_model(assignment: peer_review_sub_assignment, set: existing_section3) }

    let(:update_override1) do
      {
        id: existing_override1.id,
        due_at: 2.days.from_now,
        unlock_at: 1.day.from_now,
        lock_at: 3.days.from_now
      }
    end

    let(:update_override2) do
      {
        id: existing_override2.id,
        due_at: 3.days.from_now
      }
    end

    let(:section1) { add_section("Test Section 1", course:) }
    let(:create_override1) do
      {
        set_type: "CourseSection",
        set_id: section1.id,
        due_at: 4.days.from_now
      }
    end

    let(:section2) { add_section("Test Section 2", course:) }
    let(:create_override2) do
      {
        set_type: "CourseSection",
        set_id: section2.id,
        due_at: 5.days.from_now
      }
    end

    context "with mixed update and create overrides" do
      let(:overrides) { [update_override1, update_override2, create_override1, create_override2] }

      before do
        existing_override1
        existing_override2
        existing_override3
        allow(PeerReview::DateOverrideUpdaterService).to receive(:call).and_return(double(success?: true))
        allow(PeerReview::DateOverrideCreatorService).to receive(:call).and_return(double(success?: true))
      end

      it "partitions overrides correctly" do
        service.send(:create_or_update_peer_review_overrides)

        expect(PeerReview::DateOverrideUpdaterService).to have_received(:call).with(
          peer_review_sub_assignment:,
          overrides: [update_override1, update_override2]
        )

        expect(PeerReview::DateOverrideCreatorService).to have_received(:call).with(
          peer_review_sub_assignment:,
          overrides: [create_override1, create_override2]
        )
      end

      it "destroys orphaned overrides" do
        expect(existing_override3).to be_persisted
        service.send(:create_or_update_peer_review_overrides)
        expect(existing_override3.reload.workflow_state).to eq("deleted")
      end

      it "preserves overrides that are being updated" do
        service.send(:create_or_update_peer_review_overrides)
        expect(existing_override1.reload).to be_persisted
        expect(existing_override2.reload).to be_persisted
      end
    end

    context "with only update overrides" do
      let(:overrides) { [update_override1, update_override2] }

      before do
        existing_override1
        existing_override2
        existing_override3
        allow(PeerReview::DateOverrideUpdaterService).to receive(:call).and_return(double(success?: true))
        allow(PeerReview::DateOverrideCreatorService).to receive(:call).and_return(double(success?: true))
      end

      it "calls only the updater service" do
        service.send(:create_or_update_peer_review_overrides)

        expect(PeerReview::DateOverrideUpdaterService).to have_received(:call).with(
          peer_review_sub_assignment:,
          overrides: [update_override1, update_override2]
        )

        expect(PeerReview::DateOverrideCreatorService).not_to have_received(:call)
      end

      it "destroys the orphaned override" do
        expect(existing_override3).to be_persisted
        service.send(:create_or_update_peer_review_overrides)
        expect(existing_override3.reload.workflow_state).to eq("deleted")
      end
    end

    context "with only create overrides" do
      let(:overrides) { [create_override1, create_override2] }

      before do
        existing_override1
        existing_override2
        allow(PeerReview::DateOverrideUpdaterService).to receive(:call).and_return(double(success?: true))
        allow(PeerReview::DateOverrideCreatorService).to receive(:call).and_return(double(success?: true))
      end

      it "calls only the creator service" do
        service.send(:create_or_update_peer_review_overrides)

        expect(PeerReview::DateOverrideCreatorService).to have_received(:call).with(
          peer_review_sub_assignment:,
          overrides: [create_override1, create_override2]
        )

        expect(PeerReview::DateOverrideUpdaterService).not_to have_received(:call)
      end

      it "destroys all existing overrides" do
        expect(existing_override1).to be_persisted
        expect(existing_override2).to be_persisted

        service.send(:create_or_update_peer_review_overrides)

        expect(existing_override1.reload.workflow_state).to eq("deleted")
        expect(existing_override2.reload.workflow_state).to eq("deleted")
      end
    end

    context "with empty overrides" do
      let(:overrides) { [] }

      before do
        existing_override1
        existing_override2
        allow(PeerReview::DateOverrideUpdaterService).to receive(:call).and_return(double(success?: true))
        allow(PeerReview::DateOverrideCreatorService).to receive(:call).and_return(double(success?: true))
      end

      it "calls neither service" do
        service.send(:create_or_update_peer_review_overrides)

        expect(PeerReview::DateOverrideUpdaterService).not_to have_received(:call)
        expect(PeerReview::DateOverrideCreatorService).not_to have_received(:call)
      end

      it "destroys all existing overrides" do
        expect(existing_override1).to be_persisted
        expect(existing_override2).to be_persisted

        service.send(:create_or_update_peer_review_overrides)

        expect(existing_override1.reload.workflow_state).to eq("deleted")
        expect(existing_override2.reload.workflow_state).to eq("deleted")
      end
    end

    context "when no existing overrides" do
      let(:overrides) { [create_override1, create_override2] }

      before do
        allow(PeerReview::DateOverrideUpdaterService).to receive(:call).and_return(double(success?: true))
        allow(PeerReview::DateOverrideCreatorService).to receive(:call).and_return(double(success?: true))
      end

      it "calls only the creator service" do
        service.send(:create_or_update_peer_review_overrides)

        expect(PeerReview::DateOverrideCreatorService).to have_received(:call).with(
          peer_review_sub_assignment:,
          overrides: [create_override1, create_override2]
        )

        expect(PeerReview::DateOverrideUpdaterService).not_to have_received(:call)
      end

      it "does not attempt to destroy any overrides" do
        expect { service.send(:create_or_update_peer_review_overrides) }.not_to raise_error
      end
    end
  end

  describe "#destroy_overrides" do
    let(:destroy_section1) { add_section("Destroy Section 1", course:) }
    let(:destroy_section2) { add_section("Destroy Section 2", course:) }
    let(:destroy_section3) { add_section("Destroy Section 3", course:) }

    let(:override1) { assignment_override_model(assignment: peer_review_sub_assignment, set: destroy_section1) }
    let(:override2) { assignment_override_model(assignment: peer_review_sub_assignment, set: destroy_section2) }
    let(:override3) { assignment_override_model(assignment: peer_review_sub_assignment, set: destroy_section3) }

    before do
      override1
      override2
      override3
    end

    it "destroys specified overrides" do
      service.send(:destroy_overrides, [override1.id, override2.id])

      expect(override1.reload.workflow_state).to eq("deleted")
      expect(override2.reload.workflow_state).to eq("deleted")
      expect(override3.reload).to be_persisted
    end

    it "handles empty array" do
      expect { service.send(:destroy_overrides, []) }.not_to raise_error
    end

    it "handles non-existent override ids gracefully" do
      expect { service.send(:destroy_overrides, [999_999]) }.not_to raise_error
    end
  end

  describe "integration with ApplicationService" do
    it "inherits from ApplicationService" do
      expect(described_class.superclass).to eq(ApplicationService)
    end

    it "responds to the call class method" do
      expect(described_class).to respond_to(:call)
    end

    it "includes PeerReview::Validations module" do
      expect(described_class.included_modules).to include(PeerReview::Validations)
    end
  end
end
