# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
# spec/helpers/group_permission_helper_spec.rb

describe GroupPermissionHelper do
  include GroupPermissionHelper

  let(:context) { course_factory }
  let(:teacher) { user_factory }

  before do
    context.enroll_teacher(teacher)
    Account.default.enable_feature!(:differentiation_tags)
  end

  describe "#check_group_authorization" do
    before do
      allow(self).to receive(:authorized_action).and_return(true)
    end

    it "passes the correct rights for collaborative group add action" do
      expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_groups, :manage_groups_add])
      check_group_authorization(context:, current_user: @teacher, action_category: :add, non_collaborative: false)
    end

    it "passes the correct rights for non_collaborative group add action" do
      expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_tags_add])
      check_group_authorization(context:, current_user: @teacher, action_category: :add, non_collaborative: true)
    end

    it "passes the correct rights for collaborative group manage action" do
      expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_groups, :manage_groups_manage])
      check_group_authorization(context:, current_user: @teacher, action_category: :manage, non_collaborative: false)
    end

    it "passes the correct rights for non_collaborative group manage action" do
      expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_tags_manage])
      check_group_authorization(context:, current_user: @teacher, action_category: :manage, non_collaborative: true)
    end

    it "passes the correct rights for collaborative group delete action" do
      expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_groups, :manage_groups_delete])
      check_group_authorization(context:, current_user: @teacher, action_category: :delete, non_collaborative: false)
    end

    it "passes the correct rights for non_collaborative group delete action" do
      expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_tags_delete])
      check_group_authorization(context:, current_user: @teacher, action_category: :delete, non_collaborative: true)
    end

    it "passes the correct rights for collaborative group view action" do
      expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_groups, *RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS])
      check_group_authorization(context:, current_user: @teacher, action_category: :view, non_collaborative: false)
    end

    it "passes the correct rights for non_collaborative group view action" do
      expect(self).to receive(:authorized_action).with(context, @teacher, RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS)
      check_group_authorization(context:, current_user: @teacher, action_category: :view, non_collaborative: true)
    end

    describe "when feature flag is off is nil" do
      before do
        Account.default.disable_feature!(:differentiation_tags)
      end

      it "doesn't check non_collaborative view permissions" do
        expect(self).to receive(:authorized_action).with(context, @teacher, [])
        check_group_authorization(context:, current_user: @teacher, action_category: :view, non_collaborative: true)
      end

      it "doesn't check non_collaborative add permission" do
        expect(self).to receive(:authorized_action).with(context, @teacher, [])
        check_group_authorization(context:, current_user: @teacher, action_category: :add, non_collaborative: true)
      end

      it "doesn't check non_collaborative manage permissions" do
        expect(self).to receive(:authorized_action).with(context, @teacher, [])
        check_group_authorization(context:, current_user: @teacher, action_category: :manage, non_collaborative: true)
      end

      it "checks non_collaborative delete permissions" do
        expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_tags_delete])
        check_group_authorization(context:, current_user: @teacher, action_category: :delete, non_collaborative: true)
      end

      it "checks collaborative group add permissions" do
        expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_groups, :manage_groups_add])
        check_group_authorization(context:, current_user: @teacher, action_category: :add, non_collaborative: false)
      end

      it "checks collaborative group manage permissions" do
        expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_groups, :manage_groups_manage])
        check_group_authorization(context:, current_user: @teacher, action_category: :manage, non_collaborative: false)
      end

      it "checks collaborative group delete permissions" do
        expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_groups, :manage_groups_delete])
        check_group_authorization(context:, current_user: @teacher, action_category: :delete, non_collaborative: false)
      end

      it "checks collaborative group view permissions" do
        expect(self).to receive(:authorized_action).with(context, @teacher, [:manage_groups, *RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS])
        check_group_authorization(context:, current_user: @teacher, action_category: :view, non_collaborative: false)
      end
    end
  end

  describe "#determine_rights_for_type" do
    it "returns collaborative group rights when non_collaborative is false" do
      expect(determine_rights_for_type(:add, false)).to eq([:manage_groups, :manage_groups_add])
      expect(determine_rights_for_type(:manage, false)).to eq([:manage_groups, :manage_groups_manage])
      expect(determine_rights_for_type(:delete, false)).to eq([:manage_groups, :manage_groups_delete])
      expect(determine_rights_for_type(:view, false)).to eq([:manage_groups, *RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS])
    end

    it "returns non_collaborative group rights when non_collaborative is true" do
      expect(determine_rights_for_type(:add, true)).to eq([:manage_tags_add])
      expect(determine_rights_for_type(:manage, true)).to eq([:manage_tags_manage])
      expect(determine_rights_for_type(:delete, true)).to eq([:manage_tags_delete])
      expect(determine_rights_for_type(:view, true)).to eq(RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS)
    end

    it "handles nil non_collaborative value by treating it as false" do
      expect(determine_rights_for_type(:add, nil)).to eq([:manage_groups, :manage_groups_add])
      expect(determine_rights_for_type(:manage, nil)).to eq([:manage_groups, :manage_groups_manage])
      expect(determine_rights_for_type(:delete, nil)).to eq([:manage_groups, :manage_groups_delete])
      expect(determine_rights_for_type(:view, nil)).to eq([:manage_groups, *RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS])
    end

    it "raises an error for unsupported action_category" do
      expect { determine_rights_for_type(:invalid, false) }.to raise_error(ArgumentError)
    end
  end
end
