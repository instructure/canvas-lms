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
