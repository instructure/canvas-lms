# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_dependency "lti/platform_storage_controller"

describe Lti::PlatformStorageController do
  describe "#post_message_forwarding" do
    subject { get :post_message_forwarding }

    before do
      Account.site_admin.enable_feature!(:lti_platform_storage)
    end

    context "with lti_platform_storage flag off" do
      before do
        Account.site_admin.disable_feature!(:lti_platform_storage)
      end

      it { is_expected.to be_not_found }
    end

    context "when current domain does not match forwarding domain" do
      let(:forwarding_domain) { "https://forwarding.domain.com" }

      before do
        allow(CanvasSecurity).to receive(:config).and_return({ "lti_iss" => forwarding_domain })
      end

      it "redirects to forwarding domain" do
        subject
        expect(response.headers["Location"]).to match(forwarding_domain)
      end

      it { is_expected.to be_redirect }
    end

    context "when current domain matches forwarding domain" do
      let(:forwarding_domain) { request.base_url }

      before do
        allow(CanvasSecurity).to receive(:config).and_return({ "lti_iss" => forwarding_domain })
      end

      it "sets parent domain in js env" do
        subject
        expect(assigns.dig(:js_env, :PARENT_DOMAIN)).to eq forwarding_domain
      end

      it { is_expected.to be_successful }
    end
  end
end
