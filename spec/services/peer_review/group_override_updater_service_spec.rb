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

RSpec.describe PeerReview::GroupOverrideUpdaterService do
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
  let(:group1) { Group.create!(context: course, group_category:, name: "Group 1") }
  let(:group2) { Group.create!(context: course, group_category:, name: "Group 2") }
  let(:parent_override) do
    assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: group1)
  end
  let(:existing_override) do
    assignment_override_model(assignment: peer_review_sub_assignment, set: group1, parent_override:)
  end
  let(:due_at) { 1.week.from_now }
  let(:unlock_at) { 1.day.from_now }
  let(:lock_at) { 2.weeks.from_now }

  describe "#initialize" do
    let(:override_params) do
      {
        set_type: "Group",
        id: existing_override.id
      }
    end

    let(:service) do
      described_class.new(
        peer_review_sub_assignment:,
        override: override_params
      )
    end

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
    context "with valid parameters" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "Group",
          set_id: group1.id,
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

      it "returns the updated override" do
        result = service.call
        expect(result).to eq(existing_override)
        expect(result).to be_persisted
      end

      it "updates the override dates" do
        service.call
        existing_override.reload

        expect(existing_override.due_at).to eq(due_at)
        expect(existing_override.unlock_at).to eq(unlock_at)
        expect(existing_override.lock_at).to eq(lock_at)
        expect(existing_override.due_at_overridden).to be(true)
        expect(existing_override.unlock_at_overridden).to be(true)
        expect(existing_override.lock_at_overridden).to be(true)
      end

      it "keeps the same group if set_id matches" do
        service.call
        existing_override.reload

        expect(existing_override.set).to eq(group1)
        expect(existing_override.set_id).to eq(group1.id)
      end
    end

    context "when changing the group" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "Group",
          set_id: group2.id,
          due_at:
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      before do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: group2)
      end

      it "updates the override to use the new group" do
        service.call
        existing_override.reload

        expect(existing_override.set).to eq(group2)
        expect(existing_override.set_id).to eq(group2.id)
      end

      it "updates the dates" do
        service.call
        existing_override.reload

        expect(existing_override.due_at).to eq(due_at)
      end
    end

    context "when set_id is not provided" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "Group",
          due_at:
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "falls back to existing set_id from override" do
        result = service.call
        expect(result.set).to eq(group1)
        expect(result.set_id).to eq(group1.id)
      end

      it "applies date updates" do
        service.call
        existing_override.reload

        expect(existing_override.due_at).to eq(due_at)
      end
    end

    context "when override does not exist" do
      let(:override_params) do
        {
          id: 999_999,
          set_type: "Group",
          set_id: group1.id
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "raises OverrideNotFoundError" do
        expect { service.call }.to raise_error(PeerReview::OverrideNotFoundError, "Override does not exist")
      end
    end

    context "when override exists but is not Group type" do
      let(:section) { add_section("Test Section", course:) }
      let!(:parent_section_override) do
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section)
      end
      let(:section_override) do
        assignment_override_model(assignment: peer_review_sub_assignment, set: section, parent_override: parent_section_override)
      end

      let(:override_params) do
        {
          id: section_override.id,
          set_type: "Group",
          set_id: group1.id
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "raises OverrideNotFoundError" do
        expect { service.call }.to raise_error(PeerReview::OverrideNotFoundError, "Override does not exist")
      end
    end

    context "when set_id is missing and override.set_id is nil" do
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "Group"
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      before do
        allow(existing_override).to receive(:set_id).and_return(nil)
        allow_any_instance_of(described_class).to receive(:find_override).and_return(existing_override)
      end

      it "raises SetIdRequiredError" do
        expect { service.call }.to raise_error(PeerReview::SetIdRequiredError, "Set id is required")
      end
    end

    context "when parent assignment is not a group assignment" do
      let(:non_group_assignment) { course.assignments.create!(title: "Non-group Assignment") }
      let(:non_group_peer_review_sub_assignment) { peer_review_model(parent_assignment: non_group_assignment) }
      let(:non_group_override) do
        override = non_group_peer_review_sub_assignment.assignment_overrides.build(
          set: group1,
          dont_touch_assignment: true,
          title: "Override for Group 1",
          workflow_state: "active"
        )
        override.save!(validate: false)
        override
      end
      let(:override_params) do
        {
          id: non_group_override.id,
          set_type: "Group",
          set_id: group1.id
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment: non_group_peer_review_sub_assignment,
          override: override_params
        )
      end

      it "raises GroupAssignmentRequiredError" do
        expect { service.call }.to raise_error(
          PeerReview::GroupAssignmentRequiredError,
          "Must be a group assignment to create group overrides"
        )
      end
    end

    context "with invalid date combinations" do
      context "when due date is before unlock date" do
        let(:override_params) do
          {
            id: existing_override.id,
            set_type: "Group",
            set_id: group1.id,
            due_at: 1.day.from_now,
            unlock_at: 2.days.from_now
          }
        end

        let(:service) do
          described_class.new(
            peer_review_sub_assignment:,
            override: override_params
          )
        end

        it "raises InvalidOverrideDatesError" do
          expect { service.call }.to raise_error(PeerReview::InvalidOverrideDatesError, "Due date cannot be before unlock date")
        end
      end
    end

    context "with differentiation tags enabled" do
      let(:non_collaborative_category) do
        course.group_categories.create!(name: "Non-Collaborative Tags", non_collaborative: true)
      end
      let(:differentiation_tag) do
        Group.create!(
          context: course,
          name: "Tag 1",
          group_category: non_collaborative_category,
          non_collaborative: true
        )
      end
      let(:parent_tag_override) do
        peer_review_sub_assignment.parent_assignment.assignment_overrides.find_by(
          set_type: AssignmentOverride::SET_TYPE_GROUP,
          set: differentiation_tag
        )
      end
      let(:tag_override) do
        assignment_override_model(assignment: peer_review_sub_assignment, set: differentiation_tag, parent_override: parent_tag_override)
      end
      let(:override_params) do
        {
          id: tag_override.id,
          set_type: "Group",
          set_id: differentiation_tag.id,
          due_at:
        }
      end
      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      before do
        account.settings[:allow_assign_to_differentiation_tags] = true
        account.save!
        assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: differentiation_tag)
      end

      it "updates override for differentiation tag" do
        result = service.call
        expect(result.set).to eq(differentiation_tag)
        expect(result.due_at).to eq(due_at)
      end

      it "does not require group assignment for differentiation tags" do
        non_group_assignment = course.assignments.create!(title: "Non-group Assignment")
        non_group_peer_review_sub_assignment = peer_review_model(parent_assignment: non_group_assignment)
        non_group_parent_tag_override = assignment_override_model(assignment: non_group_assignment, set: differentiation_tag)
        tag_override_non_group = assignment_override_model(assignment: non_group_peer_review_sub_assignment, set: differentiation_tag, parent_override: non_group_parent_tag_override)
        service_with_tag = described_class.new(
          peer_review_sub_assignment: non_group_peer_review_sub_assignment,
          override: {
            id: tag_override_non_group.id,
            set_type: "Group",
            set_id: differentiation_tag.id,
            due_at:
          }
        )

        expect { service_with_tag.call }.not_to raise_error
      end
    end

    context "when group is in different group category" do
      let(:other_category) { course.group_categories.create!(name: "Other Category") }
      let(:other_group) { Group.create!(context: course, group_category: other_category, name: "Other Group") }
      let(:override_params) do
        {
          id: existing_override.id,
          set_type: "Group",
          set_id: other_group.id,
          due_at:
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "raises an error when trying to update override" do
        expect { service.call }.to raise_error(PeerReview::GroupNotFoundError, "Group does not exist")
      end
    end
  end

  describe "#find_override" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    it "finds the correct Group override by ID" do
      service.send(:find_override)
      result_with_id = peer_review_sub_assignment.assignment_overrides.find_by(
        id: existing_override.id,
        set_type: AssignmentOverride::SET_TYPE_GROUP
      )
      expect(result_with_id).to eq(existing_override)
    end

    it "returns nil for non-existent override ID" do
      result = peer_review_sub_assignment.assignment_overrides.find_by(
        id: 999_999,
        set_type: AssignmentOverride::SET_TYPE_GROUP
      )
      expect(result).to be_nil
    end

    it "returns nil for override with different set_type" do
      section = add_section("Test Section", course:)
      parent_section_override = assignment_override_model(assignment: peer_review_sub_assignment.parent_assignment, set: section)
      section_override = assignment_override_model(assignment: peer_review_sub_assignment, set: section, parent_override: parent_section_override)
      result = peer_review_sub_assignment.assignment_overrides.find_by(
        id: section_override.id,
        set_type: AssignmentOverride::SET_TYPE_GROUP
      )
      expect(result).to be_nil
    end
  end

  describe "integration with parent class methods" do
    let(:override_params) { { id: existing_override.id, set_type: "Group", set_id: group1.id } }
    let(:service) do
      described_class.new(
        peer_review_sub_assignment:,
        override: override_params
      )
    end

    describe "#fetch_set_id" do
      it "extracts the set_id from the override params" do
        set_id = service.send(:fetch_set_id)
        expect(set_id).to eq(group1.id)
      end
    end

    describe "#fetch_id" do
      it "extracts the id from the override params" do
        id = service.send(:fetch_id)
        expect(id).to eq(existing_override.id)
      end
    end

    describe "#find_group" do
      it "finds the group by id" do
        found_group = service.send(:find_group, group1.id)
        expect(found_group).to eq(group1)
      end
    end
  end

  describe "parent override tracking" do
    let!(:parent_override_group1) do
      assignment_override_model(assignment: parent_assignment, set: group1)
    end
    let!(:parent_override_group2) do
      assignment_override_model(assignment: parent_assignment, set: group2)
    end

    let!(:tracking_existing_override) do
      assignment_override_model(assignment: peer_review_sub_assignment, set: group1, parent_override: parent_override_group1)
    end

    context "when group doesn't change" do
      let(:same_group_override_params) do
        {
          id: tracking_existing_override.id,
          set_type: "Group",
          set_id: group1.id,
          due_at:
        }
      end

      let(:same_group_service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: same_group_override_params
        )
      end

      it "keeps the same parent_override" do
        same_group_service.call
        tracking_existing_override.reload
        expect(tracking_existing_override.parent_override).to eq(parent_override_group1)
      end

      it "validates parent_override still exists" do
        parent_override_group1.destroy
        expect { same_group_service.call }.to raise_error(
          PeerReview::OverrideNotFoundError,
          "Override does not exist"
        )
      end
    end

    context "when group changes" do
      let(:change_group_override_params) do
        {
          id: tracking_existing_override.id,
          set_type: "Group",
          set_id: group2.id,
          due_at:
        }
      end

      let(:change_group_service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: change_group_override_params
        )
      end

      it "updates to the new parent_override" do
        change_group_service.call
        tracking_existing_override.reload
        expect(tracking_existing_override.parent_override).to eq(parent_override_group2)
        expect(tracking_existing_override.parent_override_id).to eq(parent_override_group2.id)
      end

      it "finds parent override based on new group ID" do
        change_group_service.call
        tracking_existing_override.reload
        expect(tracking_existing_override.parent_override.set).to eq(group2)
        expect(tracking_existing_override.parent_override.set_type).to eq(AssignmentOverride::SET_TYPE_GROUP)
      end

      context "when new parent override does not exist" do
        before do
          parent_override_group2.destroy
        end

        it "raises ParentOverrideNotFoundError" do
          expect { change_group_service.call }.to raise_error(
            PeerReview::ParentOverrideNotFoundError,
            /Parent assignment Group override not found for group [\d,]+/
          )
        end
      end
    end

    it "wraps the operation in a transaction" do
      override_params = {
        id: tracking_existing_override.id,
        set_type: "Group",
        set_id: group1.id,
        due_at:
      }
      service = described_class.new(
        peer_review_sub_assignment:,
        override: override_params
      )

      expect(ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original
      service.call
    end

    context "race condition protection" do
      let(:override_params) do
        {
          id: tracking_existing_override.id,
          set_type: "Group",
          set_id: group2.id,
          due_at:
        }
      end

      let(:service) do
        described_class.new(
          peer_review_sub_assignment:,
          override: override_params
        )
      end

      it "validates parent override within transaction" do
        allow(service).to receive(:validate_group_parent_override_exists).and_call_original

        service.call

        expect(service).to have_received(:validate_group_parent_override_exists).once
      end

      it "uses a transaction to ensure atomicity of parent override lookup and update" do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original.at_least(:once)

        service.call
      end
    end
  end
end
