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

describe IgniteAgentHelper do
  include IgniteAgentHelper

  describe "ALLOWED_PAGES" do
    it "loads the configuration from YAML file" do
      expect(IgniteAgentHelper::ALLOWED_PAGES).to be_an(Array)
      expect(IgniteAgentHelper::ALLOWED_PAGES).not_to be_empty
    end

    it "contains valid controller#action pairs" do
      expect(IgniteAgentHelper::ALLOWED_PAGES).to all(match(%r{\A[\w/]+#\w+\z}))
    end
  end

  describe "#add_ignite_agent_bundle?" do
    let_once(:account) { Account.default }

    before do
      instance_variable_set(:@domain_root_account, account)
    end

    it "returns false when preview param is true" do
      allow(controller).to receive(:params).and_return({ preview: "true" })

      expect(add_ignite_agent_bundle?).to be false
    end

    it "returns false on oauth2_provider confirm page" do
      allow(controller).to receive_messages(controller_name: "oauth2_provider", action_name: "confirm", params: {})

      expect(add_ignite_agent_bundle?).to be false
    end

    context "with legacy ignite_agent_enabled feature flag" do
      before do
        account.enable_feature!(:ignite_agent_enabled)
        instance_variable_set(:@domain_root_account, account)
      end

      it "returns true when user has manage_account_settings permission" do
        admin_user = account_admin_user
        instance_variable_set(:@current_user, admin_user)

        expect(add_ignite_agent_bundle?).to be true
      end

      it "returns true when user has ignite_agent_enabled_for_user feature flag" do
        user = user_model
        user.enable_feature!(:ignite_agent_enabled_for_user)
        instance_variable_set(:@current_user, user)

        expect(add_ignite_agent_bundle?).to be true
      end
    end

    context "with oak_for_admins feature flag" do
      before do
        account.enable_feature!(:oak_for_admins)
      end

      it "returns true when user has access_oak permissions" do
        admin_user =
          account_admin_user_with_role_changes(
            role_changes: {
              manage_account_settings: false,
              access_oak: true
            },
            account:,
            role: Role.get_built_in_role("AccountMembership", root_account_id: account)
          )
        instance_variable_set(:@current_user, admin_user)

        expect(add_ignite_agent_bundle?).to be true
      end
    end
  end

  describe "#show_ignite_agent_button?" do
    it "returns true for whitelisted pages" do
      allow(controller).to receive_messages(controller_path: "users", action_name: "user_dashboard")

      expect(show_ignite_agent_button?).to be true
    end

    it "returns false for non-whitelisted pages" do
      allow(controller).to receive_messages(controller_path: "some_random_controller", action_name: "some_action")

      expect(show_ignite_agent_button?).to be false
    end

    it "returns false for New Quizzes (quiz_lti assignments)" do
      assignment = double("Assignment", quiz_lti?: true)
      instance_variable_set(:@assignment, assignment)
      allow(controller).to receive_messages(controller_path: "assignments", action_name: "show")

      expect(show_ignite_agent_button?).to be false
    end

    it "returns true for regular assignments on whitelisted pages" do
      assignment = double("Assignment", quiz_lti?: false)
      instance_variable_set(:@assignment, assignment)
      allow(controller).to receive_messages(controller_path: "assignments", action_name: "show")

      expect(show_ignite_agent_button?).to be true
    end
  end
end
