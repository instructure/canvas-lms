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

describe FeatureFlags::Hooks do
  describe "only_admins_can_enable_block_content_editor_during_eap" do
    let(:transitions) { {} }
    let(:user) { user_model }
    let(:root_account) { account_model }
    let(:course) do
      c = course_model
      allow(c).to receive(:root_account).and_return(root_account)
      c
    end
    let(:account) do
      a = account_model
      allow(a).to receive(:root_account).and_return(root_account)
      a
    end

    def stub_root_account_membership(root_account, is_member)
      where_relation = double("where_relation", exists?: is_member)
      active_relation = double("active_relation", where: where_relation)
      account_users = double("account_users", active: active_relation)
      allow(root_account).to receive(:account_users).and_return(account_users)
    end

    def expect_all_transitions_locked(transitions)
      expect(transitions["on"]).to be_present
      expect(transitions["off"]).to be_present
      expect(transitions["allowed"]).to be_present
      expect(transitions["allowed_on"]).to be_present
      expect(transitions["on"]["locked"]).to be true
      expect(transitions["off"]["locked"]).to be true
      expect(transitions["allowed"]["locked"]).to be true
      expect(transitions["allowed_on"]["locked"]).to be true
    end

    context "when block_content_editor feature is enabled" do
      before do
        allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(true)
      end

      context "when user is site admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(true)
          stub_root_account_membership(root_account, false)
        end

        it "does not lock transitions" do
          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

          expect(transitions).to be_empty
        end
      end

      context "when user is root account admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, true)
        end

        it "does not lock transitions for Course context" do
          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

          expect(transitions).to be_empty
        end

        it "does not lock transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:block_content_editor).and_return(true)
          allow(account).to receive(:root_account).and_return(root_account)

          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, account, nil, transitions)

          expect(transitions).to be_empty
        end
      end

      context "when user is not root account admin or site admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, false)
        end

        it "locks all transitions for Course context" do
          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end

        it "locks all transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:block_content_editor).and_return(true)
          allow(account).to receive(:root_account).and_return(root_account)

          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, account, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end
    end

    context "when block_content_editor feature is disabled" do
      before do
        allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)
      end

      context "when user is site admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(true)
          stub_root_account_membership(root_account, false)
        end

        it "locks all transitions" do
          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end

      context "when user is root account admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, true)
        end

        it "locks all transitions for Course context" do
          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end

        it "locks all transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)
          allow(account).to receive(:root_account).and_return(root_account)

          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, account, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end

      context "when user is not root account admin or site admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, false)
        end

        it "locks all transitions for Course context" do
          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end

        it "locks all transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)
          allow(account).to receive(:root_account).and_return(root_account)

          FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, account, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end
    end

    context "when context is not a Course or Account" do
      it "locks all transitions for other context types" do
        user_context = user_model

        FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(user, user_context, nil, transitions)

        expect_all_transitions_locked(transitions)
      end
    end

    context "edge cases" do
      it "handles nil user gracefully when feature is disabled and user is not root admin" do
        allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)
        allow(Account.site_admin).to receive(:grants_right?).with(nil, :read).and_return(false)
        stub_root_account_membership(root_account, false)

        FeatureFlags::Hooks.only_admins_can_enable_block_content_editor_during_eap(nil, course, nil, transitions)

        expect_all_transitions_locked(transitions)
      end
    end
  end

  describe "block_content_editor_flag_enabled" do
    let(:account) { account_model }
    let(:course) { course_model }

    context "when context is an Account" do
      context "when block_content_editor feature is enabled" do
        before do
          allow(account).to receive(:feature_enabled?).with(:block_content_editor).and_return(true)
        end

        it "returns true" do
          result = FeatureFlags::Hooks.block_content_editor_flag_enabled(account)

          expect(result).to be true
        end
      end

      context "when block_content_editor feature is disabled" do
        before do
          allow(account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)
        end

        it "returns false" do
          result = FeatureFlags::Hooks.block_content_editor_flag_enabled(account)

          expect(result).to be false
        end
      end
    end

    context "when context is a Course" do
      context "when block_content_editor feature is enabled on account" do
        before do
          allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(true)
        end

        it "returns true" do
          result = FeatureFlags::Hooks.block_content_editor_flag_enabled(course)

          expect(result).to be true
        end
      end

      context "when block_content_editor feature is disabled on account" do
        before do
          allow(course.account).to receive(:feature_enabled?).with(:block_content_editor).and_return(false)
        end

        it "returns false" do
          result = FeatureFlags::Hooks.block_content_editor_flag_enabled(course)

          expect(result).to be false
        end
      end
    end

    context "when context is neither Account nor Course" do
      let(:user_context) { user_model }

      it "returns false" do
        result = FeatureFlags::Hooks.block_content_editor_flag_enabled(user_context)

        expect(result).to be false
      end
    end
  end

  describe "only_admins_can_enable_a11y_checker_during_eap" do
    let(:transitions) { {} }
    let(:user) { user_model }
    let(:root_account) { account_model }
    let(:course) do
      c = course_model
      allow(c).to receive(:root_account).and_return(root_account)
      c
    end
    let(:account) do
      a = account_model
      allow(a).to receive(:root_account).and_return(root_account)
      a
    end

    def stub_root_account_membership(root_account, is_member)
      where_relation = double("where_relation", exists?: is_member)
      active_relation = double("active_relation", where: where_relation)
      account_users = double("account_users", active: active_relation)
      allow(root_account).to receive(:account_users).and_return(account_users)
    end

    def stub_subaccount_membership(account, is_member)
      where_relation = double("where_relation", exists?: is_member)
      active_relation = double("active_relation", where: where_relation)
      account_users = double("account_users", active: active_relation)
      allow(account).to receive(:account_users).and_return(account_users)
    end

    def expect_all_transitions_locked(transitions)
      expect(transitions["on"]).to be_present
      expect(transitions["off"]).to be_present
      expect(transitions["allowed"]).to be_present
      expect(transitions["allowed_on"]).to be_present
      expect(transitions["on"]["locked"]).to be true
      expect(transitions["off"]["locked"]).to be true
      expect(transitions["allowed"]["locked"]).to be true
      expect(transitions["allowed_on"]["locked"]).to be true
    end

    context "when a11y_checker feature is enabled" do
      before do
        allow(course.account).to receive(:feature_enabled?).with(:a11y_checker).and_return(true)
      end

      context "when user is site admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(true)
          stub_root_account_membership(root_account, false)
        end

        it "does not lock transitions" do
          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, course, nil, transitions)

          expect(transitions).to be_empty
        end
      end

      context "when user is root account admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, true)
        end

        it "does not lock transitions for Course context" do
          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, course, nil, transitions)

          expect(transitions).to be_empty
        end

        it "does not lock transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:a11y_checker).and_return(true)
          allow(account).to receive(:root_account).and_return(root_account)

          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, account, nil, transitions)

          expect(transitions).to be_empty
        end
      end

      context "when user is subaccount admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, false)
        end

        it "does not lock transitions for Course context" do
          stub_subaccount_membership(course.account, true)

          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, course, nil, transitions)

          expect(transitions).to be_empty
        end

        it "does not lock transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:a11y_checker).and_return(true)
          allow(account).to receive(:root_account).and_return(root_account)
          stub_subaccount_membership(account, true)

          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, account, nil, transitions)

          expect(transitions).to be_empty
        end
      end

      context "when user is not root account admin or site admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, false)
        end

        it "locks all transitions for Course context" do
          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end

        it "locks all transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:a11y_checker).and_return(true)
          allow(account).to receive(:root_account).and_return(root_account)

          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, account, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end
    end

    context "when a11y_checker feature is disabled" do
      before do
        allow(course.account).to receive(:feature_enabled?).with(:a11y_checker).and_return(false)
      end

      context "when user is site admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(true)
          stub_root_account_membership(root_account, false)
        end

        it "locks all transitions" do
          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end

      context "when user is root account admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, true)
        end

        it "locks all transitions for Course context" do
          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end

        it "locks all transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:a11y_checker).and_return(false)
          allow(account).to receive(:root_account).and_return(root_account)

          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, account, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end

      context "when user is subaccount admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, false)
        end

        it "locks all transitions for Course context" do
          stub_subaccount_membership(course.account, true)

          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end

        it "locks all transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:a11y_checker).and_return(false)
          allow(account).to receive(:root_account).and_return(root_account)
          stub_subaccount_membership(account, true)

          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, account, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end

      context "when user is not root account admin or site admin" do
        before do
          allow(Account.site_admin).to receive(:grants_right?).with(user, :read).and_return(false)
          stub_root_account_membership(root_account, false)
        end

        it "locks all transitions for Course context" do
          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, course, nil, transitions)

          expect_all_transitions_locked(transitions)
        end

        it "locks all transitions for Account context" do
          allow(account).to receive(:feature_enabled?).with(:a11y_checker).and_return(false)
          allow(account).to receive(:root_account).and_return(root_account)

          FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, account, nil, transitions)

          expect_all_transitions_locked(transitions)
        end
      end
    end

    context "when context is not a Course or Account" do
      it "locks all transitions for other context types" do
        user_context = user_model

        FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(user, user_context, nil, transitions)

        expect_all_transitions_locked(transitions)
      end
    end

    context "edge cases" do
      it "handles nil user gracefully when feature is disabled and user is not root admin" do
        allow(course.account).to receive(:feature_enabled?).with(:a11y_checker).and_return(false)
        allow(Account.site_admin).to receive(:grants_right?).with(nil, :read).and_return(false)
        stub_root_account_membership(root_account, false)

        FeatureFlags::Hooks.only_admins_can_enable_a11y_checker_during_eap(nil, course, nil, transitions)

        expect_all_transitions_locked(transitions)
      end
    end
  end

  describe "a11y_checker_flag_enabled" do
    let(:account) { account_model }
    let(:course) { course_model }

    context "when context is an Account" do
      context "when a11y_checker feature is enabled" do
        before do
          allow(account).to receive(:feature_enabled?).with(:a11y_checker).and_return(true)
        end

        it "returns true" do
          result = FeatureFlags::Hooks.a11y_checker_flag_enabled(account)

          expect(result).to be true
        end
      end

      context "when a11y_checker feature is disabled" do
        before do
          allow(account).to receive(:feature_enabled?).with(:a11y_checker).and_return(false)
        end

        it "returns false" do
          result = FeatureFlags::Hooks.a11y_checker_flag_enabled(account)

          expect(result).to be false
        end
      end
    end

    context "when context is a Course" do
      context "when a11y_checker feature is enabled on account" do
        before do
          allow(course.account).to receive(:feature_enabled?).with(:a11y_checker).and_return(true)
        end

        it "returns true" do
          result = FeatureFlags::Hooks.a11y_checker_flag_enabled(course)

          expect(result).to be true
        end
      end

      context "when a11y_checker feature is disabled on account" do
        before do
          allow(course.account).to receive(:feature_enabled?).with(:a11y_checker).and_return(false)
        end

        it "returns false" do
          result = FeatureFlags::Hooks.a11y_checker_flag_enabled(course)

          expect(result).to be false
        end
      end
    end

    context "when context is neither Account nor Course" do
      let(:user_context) { user_model }

      it "returns false" do
        result = FeatureFlags::Hooks.a11y_checker_flag_enabled(user_context)

        expect(result).to be false
      end
    end
  end

  describe "oak_visible_on_hook" do
    let(:context) { double("Context") }
    let(:current_shard) { double("Shard", database_server: double(config: { region: "us-east-1" })) }
    let(:oak_predicate) { instance_double(FeatureFlags::OakPredicate) }

    before do
      allow(Shard).to receive(:current).and_return(current_shard)
      allow(FeatureFlags::OakPredicate).to receive(:new).and_return(oak_predicate)
      allow(oak_predicate).to receive(:call)
    end

    it "creates a new OakPredicate with context and region" do
      expect(FeatureFlags::OakPredicate).to receive(:new).with(context, "us-east-1")

      FeatureFlags::Hooks.oak_visible_on_hook(context)
    end

    it "calls .call on the OakPredicate instance" do
      expect(oak_predicate).to receive(:call)

      FeatureFlags::Hooks.oak_visible_on_hook(context)
    end
  end

  describe "oak_for_users_visible_on_hook" do
    let(:context) { double("Context") }
    let(:domain_root_account) { double("Account") }

    before do
      allow(Account).to receive(:current_domain_root_account).and_return(domain_root_account)
      allow(FeatureFlags::Hooks).to receive(:oak_visible_on_hook).and_return(true)
      allow(Oak::PermissionChecker).to receive(:user_permitted?).and_return(true)
    end

    context "when oak_visible_on_hook returns false" do
      before do
        allow(FeatureFlags::Hooks).to receive(:oak_visible_on_hook).and_return(false)
      end

      it "returns false without checking permission" do
        expect(Oak::PermissionChecker).not_to receive(:user_permitted?)

        result = FeatureFlags::Hooks.oak_for_users_visible_on_hook(context)

        expect(result).to be false
      end
    end

    context "when oak_visible_on_hook returns true" do
      before do
        allow(FeatureFlags::Hooks).to receive(:oak_visible_on_hook).and_return(true)
      end

      it "checks user_permitted? with proper parameters" do
        expect(Oak::PermissionChecker).to receive(:user_permitted?).with(context, domain_root_account)

        FeatureFlags::Hooks.oak_for_users_visible_on_hook(context)
      end

      it "returns true when user has oak permission" do
        allow(Oak::PermissionChecker).to receive(:user_permitted?).and_return(true)

        result = FeatureFlags::Hooks.oak_for_users_visible_on_hook(context)

        expect(result).to be true
      end

      it "returns false when user does not have oak permission" do
        allow(Oak::PermissionChecker).to receive(:user_permitted?).and_return(false)

        result = FeatureFlags::Hooks.oak_for_users_visible_on_hook(context)

        expect(result).to be false
      end
    end
  end
end
