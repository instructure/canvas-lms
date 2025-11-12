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

RSpec.describe PeerReview::GroupOverrideCommonService do
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
  let(:override_params) do
    {
      set_type: "Group",
      set_id: group.id,
      due_at: 2.days.from_now,
      unlock_at: 1.day.from_now,
      lock_at: 3.days.from_now
    }
  end

  describe "#initialize" do
    it "sets the instance variables correctly" do
      service = described_class.new(
        peer_review_sub_assignment:,
        override: override_params
      )

      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to eq(peer_review_sub_assignment)
      expect(service.instance_variable_get(:@override)).to eq(override_params)
    end

    it "allows nil values for both parameters" do
      service = described_class.new
      expect(service.instance_variable_get(:@peer_review_sub_assignment)).to be_nil
      expect(service.instance_variable_get(:@override)).to eq({})
    end
  end

  describe "#fetch_set_id" do
    let(:service) { described_class.new(override: override_params) }

    it "returns the set_id value from the override" do
      expect(service.send(:fetch_set_id)).to eq(group.id)
    end

    context "when override contains set_id as nil" do
      let(:override_with_nil) { override_params.merge(set_id: nil) }
      let(:service_with_nil) { described_class.new(override: override_with_nil) }

      it "returns nil" do
        expect(service_with_nil.send(:fetch_set_id)).to be_nil
      end
    end

    context "when override does not contain set_id" do
      let(:override_without_set_id) { override_params.except(:set_id) }
      let(:service_without_set_id) { described_class.new(override: override_without_set_id) }

      it "returns nil" do
        expect(service_without_set_id.send(:fetch_set_id)).to be_nil
      end
    end

    context "when override is nil" do
      let(:service_without_override) { described_class.new }

      it "returns nil when key is not found" do
        expect(service_without_override.send(:fetch_set_id)).to be_nil
      end
    end
  end

  describe "#fetch_id" do
    let(:override_with_id) { override_params.merge(id: 123) }
    let(:service) { described_class.new(override: override_with_id) }

    it "returns the id value from the override" do
      expect(service.send(:fetch_id)).to eq(123)
    end

    context "when override does not contain id" do
      let(:service_without_id) { described_class.new(override: override_params) }

      it "returns nil" do
        expect(service_without_id.send(:fetch_id)).to be_nil
      end
    end
  end

  describe "#find_group" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    it "returns the group when it exists in the correct group category" do
      result = service.send(:find_group, group.id)
      expect(result).to eq(group)
    end

    context "when group does not exist" do
      it "returns nil" do
        result = service.send(:find_group, 999_999)
        expect(result).to be_nil
      end
    end

    context "when group exists but in different group category" do
      let(:other_category) { course.group_categories.create!(name: "Other Category") }
      let(:other_group) { Group.create!(context: course, group_category: other_category, name: "Other Group") }

      it "returns nil" do
        result = service.send(:find_group, other_group.id)
        expect(result).to be_nil
      end
    end

    context "when parent assignment has no group category" do
      let(:non_group_assignment) { course.assignments.create!(title: "Non-group Assignment") }
      let(:non_group_sub_assignment) { peer_review_model(parent_assignment: non_group_assignment) }
      let(:service_without_category) { described_class.new(peer_review_sub_assignment: non_group_sub_assignment) }

      it "returns nil" do
        result = service_without_category.send(:find_group, group.id)
        expect(result).to be_nil
      end
    end

    context "when group is deleted" do
      before { group.destroy }

      it "returns nil" do
        result = service.send(:find_group, group.id)
        expect(result).to be_nil
      end
    end
  end

  describe "#differentiation_tag_override?" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    context "when differentiation tags are enabled" do
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

      before do
        account.settings[:allow_assign_to_differentiation_tags] = true
        account.save!
      end

      it "returns true for non-collaborative groups (differentiation tags)" do
        result = service.send(:differentiation_tag_override?, differentiation_tag.id)
        expect(result).to be(true)
      end

      it "returns false for collaborative groups" do
        collaborative_group = Group.create!(
          context: course,
          name: "Collaborative Group",
          group_category:,
          non_collaborative: false
        )
        result = service.send(:differentiation_tag_override?, collaborative_group.id)
        expect(result).to be(false)
      end

      context "when differentiation tag does not exist" do
        it "returns false" do
          result = service.send(:differentiation_tag_override?, 999_999)
          expect(result).to be(false)
        end
      end
    end

    context "when account does not allow differentiation tags" do
      before do
        account.settings[:allow_assign_to_differentiation_tags] = false
        account.save!
      end

      it "returns false" do
        result = service.send(:differentiation_tag_override?, 123)
        expect(result).to be(false)
      end
    end
  end

  describe "#find_differentiation_tag" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }
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

    it "returns the differentiation tag when it exists" do
      result = service.send(:find_differentiation_tag, differentiation_tag.id)
      expect(result).to eq(differentiation_tag)
    end

    it "returns nil when differentiation tag does not exist" do
      result = service.send(:find_differentiation_tag, 999_999)
      expect(result).to be_nil
    end
  end

  describe "#course" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    it "returns the course from the peer review sub assignment" do
      result = service.send(:course)
      expect(result).to eq(course)
    end

    it "memoizes the course to avoid repeated queries" do
      service.send(:course)
      expect(peer_review_sub_assignment).not_to receive(:course)
      service.send(:course)
    end
  end

  describe "#account" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    it "returns the account from the peer review sub assignment's course" do
      result = service.send(:account)
      expect(result).to eq(account)
    end

    it "memoizes the account to avoid repeated queries" do
      service.send(:account)
      expect(service.send(:course)).not_to receive(:account)
      service.send(:account)
    end
  end

  describe "#differentiation_tags_enabled_for_context?" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    context "when account setting allows differentiation tags" do
      before do
        account.settings[:allow_assign_to_differentiation_tags] = true
        account.save!
      end

      it "returns true" do
        result = service.send(:differentiation_tags_enabled_for_context?)
        expect(result).to be(true)
      end
    end

    context "when account setting does not allow differentiation tags" do
      before do
        account.settings[:allow_assign_to_differentiation_tags] = false
        account.save!
      end

      it "returns false" do
        result = service.send(:differentiation_tags_enabled_for_context?)
        expect(result).to be(false)
      end
    end
  end

  describe "module inclusion" do
    it "includes PeerReview::Validations module" do
      expect(described_class.included_modules).to include(PeerReview::Validations)
    end

    it "includes PeerReview::DateOverrider module" do
      expect(described_class.included_modules).to include(PeerReview::DateOverrider)
    end

    it "responds to validation methods from PeerReview::Validations" do
      service = described_class.new
      expect(service).to respond_to(:validate_parent_assignment)
      expect(service).to respond_to(:validate_peer_reviews_enabled)
      expect(service).to respond_to(:validate_feature_enabled)
      expect(service).to respond_to(:validate_peer_review_dates)
      expect(service).to respond_to(:validate_set_id_required)
      expect(service).to respond_to(:validate_override_exists)
    end

    it "responds to date override methods from PeerReview::DateOverrider" do
      service = described_class.new
      expect(service).to respond_to(:apply_overridden_dates)
    end
  end

  describe "integration with ApplicationService" do
    it "inherits from ApplicationService" do
      expect(described_class.superclass).to eq(ApplicationService)
    end

    it "responds to the call class method" do
      expect(described_class).to respond_to(:call)
    end
  end

  describe "edge cases" do
    context "when override contains unexpected keys" do
      let(:override_with_extras) do
        override_params.merge(
          extra_key: "unexpected",
          another_key: 123
        )
      end

      let(:service_with_extras) { described_class.new(override: override_with_extras) }

      it "extracts known keys correctly" do
        expect(service_with_extras.send(:fetch_set_id)).to eq(group.id)
      end
    end

    context "with nil peer_review_sub_assignment" do
      let(:service_without_sub_assignment) { described_class.new(override: override_params) }

      it "handles missing peer_review_sub_assignment gracefully" do
        expect { service_without_sub_assignment.send(:fetch_set_id) }.not_to raise_error
      end
    end
  end

  describe "#find_parent_override" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    context "when parent override exists with matching group ID" do
      let!(:parent_override) do
        assignment_override_model(assignment: parent_assignment, set: group)
      end

      it "finds the parent override based on group ID" do
        result = service.send(:find_parent_override, group.id)
        expect(result).to eq(parent_override)
      end

      it "returns an AssignmentOverride instance" do
        result = service.send(:find_parent_override, group.id)
        expect(result).to be_a(AssignmentOverride)
      end

      it "returns override with correct set_type" do
        result = service.send(:find_parent_override, group.id)
        expect(result.set_type).to eq(AssignmentOverride::SET_TYPE_GROUP)
      end
    end

    context "when parent override does not exist" do
      it "returns nil" do
        result = service.send(:find_parent_override, group.id)
        expect(result).to be_nil
      end
    end

    context "when parent override is deleted" do
      let(:parent_override) do
        override = assignment_override_model(assignment: parent_assignment, set: group)
        override.destroy
        override
      end

      it "returns nil for deleted override" do
        result = service.send(:find_parent_override, group.id)
        expect(result).to be_nil
      end
    end
  end

  describe "#parent_assignment" do
    let(:service) { described_class.new(peer_review_sub_assignment:) }

    it "returns the parent assignment of the peer review sub assignment" do
      result = service.send(:parent_assignment)
      expect(result).to eq(peer_review_sub_assignment.parent_assignment)
    end

    it "returns an Assignment instance" do
      result = service.send(:parent_assignment)
      expect(result).to be_a(Assignment)
    end
  end
end
