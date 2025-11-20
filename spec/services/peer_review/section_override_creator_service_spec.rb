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

RSpec.describe PeerReview::SectionOverrideCreatorService do
  let(:course) { course_model(name: "Test Course") }
  let(:section) { add_section("Test Section", course:) }
  let(:peer_review_sub_assignment) { peer_review_model(course:) }
  let(:due_hour) { 9 } # Set time to avoid potential issues with end-of-day boundaries that could cause intermittent test failures
  let(:due_at) { 1.week.from_now.change(hour: due_hour) }
  let(:unlock_at) { 1.day.from_now.change(hour: due_hour) }
  let(:lock_at) { 2.weeks.from_now.change(hour: due_hour) }
  let(:override_params) do
    {
      set_id: section.id,
      set_type: "CourseSection",
      due_at:,
      unlock_at:,
      lock_at:,
      unassign_item: false
    }
  end

  let(:service) do
    described_class.new(
      peer_review_sub_assignment:,
      override: override_params
    )
  end

  describe "#initialize" do
    it "sets the instance variables correctly" do
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@override)).to eq(override_params)
    end

    it "inherits from PeerReview::SectionOverrideCommonService" do
      expect(described_class.superclass).to eq(PeerReview::SectionOverrideCommonService)
    end
  end

  describe "#call" do
    context "with valid parameters" do
      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section)
      end

      it "creates an assignment override for the section" do
        expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
      end

      it "returns the created assignment override" do
        override = service.call
        expect(override).to be_an(AssignmentOverride)
        expect(override).to be_persisted
      end

      it "sets the correct section on the override" do
        override = service.call
        expect(override.set).to eq(section)
      end

      it "applies the correct dates to the override" do
        override = service.call
        expect(override.due_at).to eq(due_at)
        expect(override.unlock_at).to eq(unlock_at)
        expect(override.lock_at).to eq(lock_at)
        expect(override.due_at_overridden).to be(true)
        expect(override.unlock_at_overridden).to be(true)
        expect(override.lock_at_overridden).to be(true)
      end

      it "sets the unassign_item property" do
        override = service.call
        expect(override.unassign_item).to be(false)
      end

      it "sets dont_touch_assignment to true" do
        override = service.call
        expect(override.dont_touch_assignment).to be(true)
      end
    end

    context "with unassign_item set to true" do
      let(:override_params) do
        {
          set_id: section.id,
          unassign_item: true
        }
      end

      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section)
      end

      it "sets unassign_item to true on the override" do
        override = service.call
        expect(override.unassign_item).to be(true)
      end
    end

    context "with partial override dates" do
      let(:override_params) do
        {
          set_id: section.id,
          due_at:
        }
      end

      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section)
      end

      it "only applies the provided dates" do
        override = service.call
        expect(override.due_at).to eq(due_at)
        expect(override.unlock_at).to be_nil
        expect(override.lock_at).to be_nil
        expect(override.due_at_overridden).to be(true)
        expect(override.unlock_at_overridden).to be(false)
        expect(override.lock_at_overridden).to be(false)
      end
    end

    context "when set_id is missing" do
      let(:override_params) { { due_at: } }

      it "raises SetIdRequiredError" do
        expect { service.call }.to raise_error(PeerReview::SetIdRequiredError, "Set id is required")
      end
    end

    context "when set_id is nil" do
      let(:override_params) { { set_id: nil, due_at: } }

      it "raises SetIdRequiredError" do
        expect { service.call }.to raise_error(PeerReview::SetIdRequiredError, "Set id is required")
      end
    end

    context "when section does not exist" do
      let(:override_params) { { set_id: 999_999, due_at: } }

      it "raises ActiveRecord::RecordNotFound" do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when peer review sub assignment has no course" do
      let(:peer_review_sub_assignment_without_course) do
        peer_review_sub = peer_review_model(course:)
        allow(peer_review_sub).to receive(:course).and_return(nil)
        peer_review_sub
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment: peer_review_sub_assignment_without_course,
          override: override_params
        )
      end

      it "raises SectionNotFoundError" do
        allow(peer_review_sub_assignment_without_course).to receive(:course).and_return(nil)
        expect { service.call }.to raise_error(PeerReview::SectionNotFoundError, "Section does not exist")
      end
    end

    context "with invalid date combinations" do
      context "when due date is before unlock date" do
        let(:override_params) do
          {
            set_id: section.id,
            due_at: 1.day.from_now.change(hour: due_hour),
            unlock_at: 2.days.from_now.change(hour: due_hour)
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Due date cannot be before unlock date")
        end
      end

      context "when due date is after lock date" do
        let(:override_params) do
          {
            set_id: section.id,
            due_at: 3.days.from_now.change(hour: due_hour),
            lock_at: 2.days.from_now.change(hour: due_hour)
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Due date cannot be after lock date")
        end
      end

      context "when unlock date is after lock date" do
        let(:override_params) do
          {
            set_id: section.id,
            unlock_at: 3.days.from_now.change(hour: due_hour),
            lock_at: 2.days.from_now.change(hour: due_hour)
          }
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Unlock date cannot be after lock date")
        end
      end
    end
  end

  describe "integration with parent class methods" do
    describe "#course_section" do
      it "finds the section from the peer review sub assignment's course" do
        section_result = service.send(:course_section, section.id)
        expect(section_result).to eq(section)
      end

      context "when peer review sub assignment is nil" do
        let(:service_with_nil) do
          described_class.new(
            peer_review_sub_assignment: nil,
            override: override_params
          )
        end

        it "returns nil safely" do
          section_result = service_with_nil.send(:course_section, section.id)
          expect(section_result).to be_nil
        end
      end
    end

    describe "#fetch_set_id" do
      it "extracts the set_id from the override params" do
        set_id = service.send(:fetch_set_id)
        expect(set_id).to eq(section.id)
      end
    end

    describe "#fetch_unassign_item" do
      it "extracts the unassign_item from the override params" do
        unassign_item = service.send(:fetch_unassign_item)
        expect(unassign_item).to be(false)
      end

      context "when unassign_item is not provided" do
        let(:override_params) { { set_id: section.id } }

        it "defaults to false" do
          unassign_item = service.send(:fetch_unassign_item)
          expect(unassign_item).to be(false)
        end
      end
    end
  end

  describe "parent override tracking" do
    let(:parent_assignment) { peer_review_sub_assignment.parent_assignment }
    let!(:parent_override) do
      assignment_override_model(assignment: parent_assignment, set: section)
    end

    it "sets the parent_override on the created override" do
      override = service.call
      expect(override.parent_override).to eq(parent_override)
      expect(override.parent_override_id).to eq(parent_override.id)
    end

    it "finds the correct parent override based on section ID" do
      override = service.call
      expect(override.parent_override.set).to eq(section)
      expect(override.parent_override.set_type).to eq(AssignmentOverride::SET_TYPE_COURSE_SECTION)
    end

    context "when parent override does not exist" do
      before do
        parent_override.destroy
      end

      it "raises ParentOverrideNotFoundError" do
        expect { service.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment Section override not found for section [\d,]+/
        )
      end
    end

    context "when parent override exists for different section" do
      let(:other_section) { add_section("Other Section", course:) }
      let(:other_parent_override) do
        assignment_override_model(assignment: parent_assignment, set: other_section)
      end

      before do
        parent_override.destroy
      end

      it "raises ParentOverrideNotFoundError" do
        expect { service.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment Section override not found for section [\d,]+/
        )
      end
    end

    it "wraps the operation in a transaction" do
      expect(ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original
      service.call
    end

    context "transaction protection for parent override lookup" do
      it "validates parent override exists within transaction" do
        allow(service).to receive(:validate_section_parent_override_exists).and_call_original

        service.call

        expect(service).to have_received(:validate_section_parent_override_exists).once
      end

      it "rolls back if parent override validation fails during transaction" do
        allow(service).to receive(:validate_section_parent_override_exists).and_raise(PeerReview::ParentOverrideNotFoundError, "Test error")

        expect { service.call }.to raise_error(PeerReview::ParentOverrideNotFoundError)
        expect(peer_review_sub_assignment.assignment_overrides.count).to eq(0)
      end

      it "finds parent override inside the transaction block" do
        find_parent_called_in_transaction = false

        allow(service).to receive(:find_parent_override).and_wrap_original do |method, *args|
          find_parent_called_in_transaction = ActiveRecord::Base.connection.transaction_open?
          method.call(*args)
        end

        service.call

        expect(find_parent_called_in_transaction).to be true
      end
    end
  end
end
