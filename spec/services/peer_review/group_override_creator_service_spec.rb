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

RSpec.describe PeerReview::GroupOverrideCreatorService do
  let(:account) { account_model }
  let(:course) { course_model(name: "Test Course", account:) }
  let(:group_category) { course.group_categories.create!(name: "Project Groups") }
  let(:parent_assignment) do
    course.assignments.create!(
      title: "Group Assignment",
      group_category:,
      peer_reviews: true
    )
  end
  let(:peer_review_sub_assignment) { peer_review_model(parent_assignment:) }
  let(:group) { Group.create!(context: course, group_category:, name: "Group 1") }
  let(:due_at) { 1.week.from_now }
  let(:unlock_at) { 1.day.from_now }
  let(:lock_at) { 2.weeks.from_now }
  let(:override_params) do
    {
      set_type: "Group",
      set_id: group.id,
      due_at:,
      unlock_at:,
      lock_at:
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

    it "allows nil values for both parameters" do
      service = described_class.new
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@override)).to eq({})
    end

    it "inherits from PeerReview::GroupOverrideCommonService" do
      expect(described_class.superclass).to eq(PeerReview::GroupOverrideCommonService)
    end
  end

  describe "#call" do
    context "with valid parameters for group override" do
      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: group)
      end

      it "creates override for the group" do
        expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
      end

      it "returns the created override" do
        override = service.call
        expect(override).to be_an(AssignmentOverride)
        expect(override).to be_persisted
      end

      it "sets the correct set to the group" do
        override = service.call
        expect(override.set).to eq(group)
        expect(override.set_type).to eq(AssignmentOverride::SET_TYPE_GROUP)
        expect(override.set_id).to eq(group.id)
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

      it "sets dont_touch_assignment to true" do
        override = service.call
        expect(override.dont_touch_assignment).to be(true)
      end
    end

    context "with partial override dates" do
      let(:override_params) do
        {
          set_type: "Group",
          set_id: group.id,
          due_at:
        }
      end

      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: group)
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
      let(:override_params) do
        {
          set_type: "Group",
          due_at:
        }
      end

      it "raises SetIdRequiredError" do
        expect { service.call }.to raise_error(PeerReview::SetIdRequiredError, "Set id is required")
      end
    end

    context "when set_id is nil" do
      let(:override_params) do
        {
          set_type: "Group",
          set_id: nil,
          due_at:
        }
      end

      it "raises SetIdRequiredError" do
        expect { service.call }.to raise_error(PeerReview::SetIdRequiredError, "Set id is required")
      end
    end

    context "when group does not exist" do
      let(:override_params) do
        {
          set_type: "Group",
          set_id: 999_999,
          due_at:
        }
      end

      it "raises GroupNotFoundError error" do
        expect { service.call }.to raise_error(PeerReview::GroupNotFoundError, "Group does not exist")
      end
    end

    context "when the parent assignment is not a group assignment" do
      let(:non_group_assignment) { course.assignments.create!(title: "Non-group Assignment") }
      let(:non_group_peer_review_sub_assignment) { peer_review_model(parent_assignment: non_group_assignment) }
      let(:service_without_group_category) do
        described_class.new(
          peer_review_sub_assignment: non_group_peer_review_sub_assignment,
          override: override_params
        )
      end

      it "raises GroupAssignmentRequiredError" do
        expect { service_without_group_category.call }.to raise_error(
          PeerReview::GroupAssignmentRequiredError,
          "Must be a group assignment to create group overrides"
        )
      end
    end

    context "with invalid date combinations" do
      context "when due date is before unlock date" do
        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            due_at: 1.day.from_now,
            unlock_at: 2.days.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidDatesError, "Due date cannot be before unlock date")
        end
      end

      context "when due date is after lock date" do
        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            due_at: 3.days.from_now,
            lock_at: 2.days.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidDatesError, "Due date cannot be after lock date")
        end
      end

      context "when unlock date is after lock date" do
        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            unlock_at: 3.days.from_now,
            lock_at: 2.days.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidDatesError, "Unlock date cannot be after lock date")
        end
      end
    end

    context "with differentiation tags enabled" do
      let(:non_collaborative_category) do
        course.group_categories.create!(name: "Non-Collaborative Group Category", non_collaborative: true)
      end
      let(:differentiation_tag) do
        Group.create!(
          context: course,
          name: "Tag 1",
          group_category: non_collaborative_category,
          non_collaborative: true
        )
      end
      let(:override_params) do
        {
          set_type: "Group",
          set_id: differentiation_tag.id,
          due_at:
        }
      end

      before do
        account.settings[:allow_assign_to_differentiation_tags] = true
        account.save!
        peer_review_sub_assignment.parent_assignment.assignment_overrides.create!(
          set_type: AssignmentOverride::SET_TYPE_GROUP,
          set: differentiation_tag,
          dont_touch_assignment: true
        )
      end

      it "creates override for differentiation tag" do
        override = service.call
        expect(override).to be_persisted
        expect(override.set).to eq(differentiation_tag)
      end

      it "does not require group assignment for differentiation tags" do
        non_group_assignment = course.assignments.create!(title: "Non-group Assignment")
        non_group_peer_review_sub_assignment = peer_review_model(parent_assignment: non_group_assignment)
        assignment_override_model(assignment: non_group_assignment, set: differentiation_tag)
        service_with_tag = described_class.new(
          peer_review_sub_assignment: non_group_peer_review_sub_assignment,
          override: override_params
        )

        expect { service_with_tag.call }.not_to raise_error
      end
    end

    context "when group is in different group category" do
      let(:other_category) { course.group_categories.create!(name: "Other Category") }
      let(:other_group) { Group.create!(context: course, group_category: other_category, name: "Other Group") }
      let(:override_params) do
        {
          set_type: "Group",
          set_id: other_group.id,
          due_at:
        }
      end

      it "raises an error when trying to create override" do
        expect { service.call }.to raise_error(PeerReview::GroupNotFoundError, "Group does not exist")
      end
    end

    context "validation against parent override dates" do
      context "when peer review dates fall within parent override dates" do
        before do
          assignment_override_model(
            assignment: parent_assignment,
            set: group,
            unlock_at: 1.day.from_now,
            lock_at: 3.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            unlock_at: 2.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 2.weeks.from_now
          }
        end

        it "creates the override successfully" do
          expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
        end
      end

      context "when peer review unlock_at is before parent unlock_at" do
        before do
          assignment_override_model(
            assignment: parent_assignment,
            set: group,
            unlock_at: 2.days.from_now,
            lock_at: 3.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            unlock_at: 1.day.from_now,
            due_at: 1.week.from_now,
            lock_at: 2.weeks.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override unlock date cannot be before parent override unlock date/
          )
        end
      end

      context "when peer review due_at is after parent lock_at" do
        before do
          assignment_override_model(
            assignment: parent_assignment,
            set: group,
            unlock_at: 1.day.from_now,
            lock_at: 2.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            unlock_at: 2.days.from_now,
            due_at: 3.weeks.from_now,
            lock_at: 4.weeks.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override due date cannot be after parent override lock date/
          )
        end
      end

      context "when peer review lock_at is after parent lock_at" do
        before do
          assignment_override_model(
            assignment: parent_assignment,
            set: group,
            unlock_at: 1.day.from_now,
            lock_at: 2.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            unlock_at: 2.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 3.weeks.from_now
          }
        end

        it "raises InvalidDatesError" do
          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review override lock date cannot be after parent override lock date/
          )
        end
      end

      context "when parent override has no unlock_at" do
        before do
          assignment_override_model(
            assignment: parent_assignment,
            set: group,
            lock_at: 2.weeks.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            unlock_at: 1.day.ago,
            due_at: 1.week.from_now,
            lock_at: 10.days.from_now
          }
        end

        it "does not validate against parent unlock_at" do
          expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
        end
      end

      context "when parent override has no lock_at" do
        before do
          assignment_override_model(
            assignment: parent_assignment,
            set: group,
            unlock_at: 1.day.from_now
          )
        end

        let(:override_params) do
          {
            set_type: "Group",
            set_id: group.id,
            unlock_at: 2.days.from_now,
            due_at: 1.month.from_now,
            lock_at: 2.months.from_now
          }
        end

        it "does not validate against parent lock_at" do
          expect { service.call }.to change { peer_review_sub_assignment.assignment_overrides.count }.by(1)
        end
      end
    end
  end

  describe "integration with parent class methods" do
    describe "#fetch_set_id" do
      it "extracts the set_id from the override params" do
        set_id = service.send(:fetch_set_id)
        expect(set_id).to eq(group.id)
      end
    end

    describe "#find_group" do
      it "finds the group by id" do
        found_group = service.send(:find_group, group.id)
        expect(found_group).to eq(group)
      end
    end

    describe "#differentiation_tag_override?" do
      context "when set_id is a group" do
        it "returns false for collaborative group" do
          result = service.send(:differentiation_tag_override?, group.id)
          expect(result).to be(false)
        end
      end
    end
  end

  describe "parent override tracking" do
    let!(:parent_override) do
      assignment_override_model(assignment: parent_assignment, set: group)
    end

    it "sets the parent_override on the created override" do
      override = service.call
      expect(override.parent_override).to eq(parent_override)
      expect(override.parent_override_id).to eq(parent_override.id)
    end

    it "finds the correct parent override based on group ID" do
      override = service.call
      expect(override.parent_override.set).to eq(group)
      expect(override.parent_override.set_type).to eq(AssignmentOverride::SET_TYPE_GROUP)
    end

    context "when parent override does not exist" do
      before do
        parent_override.destroy
      end

      it "raises ParentOverrideNotFoundError" do
        expect { service.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment Group override not found for group [\d,]+/
        )
      end
    end

    context "when parent override exists for different group" do
      let(:other_group) { Group.create!(context: course, group_category:, name: "Group 2") }
      let(:other_parent_override) do
        assignment_override_model(assignment: parent_assignment, set: other_group)
      end

      before do
        parent_override.destroy
      end

      it "raises ParentOverrideNotFoundError" do
        expect { service.call }.to raise_error(
          PeerReview::ParentOverrideNotFoundError,
          /Parent assignment Group override not found for group [\d,]+/
        )
      end
    end

    it "wraps the operation in a transaction" do
      expect(ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original
      service.call
    end

    context "transaction protection for parent override lookup" do
      it "validates parent override exists within transaction" do
        allow(service).to receive(:validate_group_parent_override_exists).and_call_original

        service.call

        expect(service).to have_received(:validate_group_parent_override_exists).once
      end

      it "rolls back if parent override validation fails during transaction" do
        allow(service).to receive(:validate_group_parent_override_exists).and_raise(PeerReview::ParentOverrideNotFoundError, "Test error")

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
