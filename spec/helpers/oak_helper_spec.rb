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

describe OakHelper do
  include OakHelper

  describe "#add_oak_bundle?" do
    let_once(:account) { Account.default }
    let_once(:user) { account_admin_user }

    before do
      Account.current_domain_root_account = account
      instance_variable_set(:@current_user, user)
    end

    context "when preview param is true" do
      before do
        allow(controller).to receive(:params).and_return({ preview: "true" })
      end

      it "returns false" do
        expect(add_oak_bundle?).to be false
      end
    end

    context "when session has pending_otp" do
      before do
        allow(controller).to receive(:session).and_return({ pending_otp: true })
      end

      it "returns false" do
        expect(add_oak_bundle?).to be false
      end
    end

    context "when on a oauth2_provider confirm page" do
      before do
        allow(controller).to receive_messages(controller_name: "oauth2_provider", action_name: "confirm", params: {})
      end

      it "returns false" do
        expect(add_oak_bundle?).to be false
      end
    end

    context "when request path starts with /login" do
      before do
        allow(request).to receive(:path).and_return("/login/some_path")
      end

      it "returns false" do
        expect(add_oak_bundle?).to be false
      end
    end

    context "when current user is nil" do
      before do
        instance_variable_set(:@current_user, nil)
      end

      it "returns false" do
        expect(add_oak_bundle?).to be false
      end
    end

    context "with oak_for_users feature flag" do
      before do
        account.enable_feature!(:ignite_agent_enabled)
      end

      context "when oak_for_users is disabled" do
        before do
          user.disable_feature!(:oak_for_users)
        end

        it "returns false" do
          expect(add_oak_bundle?).to be false
        end
      end

      context "when oak_for_users is not set (defaults to allowed)" do
        it "returns true" do
          expect(add_oak_bundle?).to be true
        end
      end
    end
  end
end
