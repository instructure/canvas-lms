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

require "spec_helper"

describe IgniteAgentHelper do
  include IgniteAgentHelper

  let_once(:user) { user_factory(active_all: true) }
  let_once(:account) { Account.default }
  let_once(:course) { course_factory(account:) }

  before do
    @domain_root_account = account
    @current_user = user
    allow(Services::IgniteAgent).to receive_messages(
      launch_url: "https://ignite.example.com/launch",
      backend_url: "https://ignite.example.com/api"
    )
    allow(self).to receive(:session).and_return({})
  end

  describe "#add_ignite_agent_bundle" do
    context "when no user is logged in" do
      before do
        @current_user = nil
      end

      it "does not add the ignite agent bundle" do
        expect(self).not_to receive(:js_bundle)
        expect(self).not_to receive(:remote_env)

        add_ignite_agent_bundle
      end
    end

    context "when ignite_agent_enabled feature is disabled" do
      before do
        account.disable_feature!(:ignite_agent_enabled)
      end

      it "does not add the ignite agent bundle" do
        expect(self).not_to receive(:js_bundle)
        expect(self).not_to receive(:remote_env)

        add_ignite_agent_bundle
      end
    end

    context "when ignite_agent_enabled feature is enabled" do
      before do
        account.enable_feature!(:ignite_agent_enabled)
      end

      context "when user does not have access_ignite_agent permission" do
        it "does not add the ignite agent bundle" do
          expect(self).not_to receive(:js_bundle)
          expect(self).not_to receive(:remote_env)

          add_ignite_agent_bundle
        end
      end

      context "when user has access_ignite_agent permission" do
        before do
          account.role_overrides.create!(
            permission: :access_ignite_agent,
            role: admin_role,
            enabled: true
          )
          account.account_users.create!(user:, role: admin_role)
        end

        it "adds the ignite agent bundle and remote env" do
          expect(self).to receive(:js_bundle).with(:ignite_agent)
          expect(self).to receive(:remote_env).with(
            ignite_agent: {
              launch_url: "https://ignite.example.com/launch",
              backend_url: "https://ignite.example.com/api"
            }
          )

          add_ignite_agent_bundle
        end
      end
    end
  end
end
