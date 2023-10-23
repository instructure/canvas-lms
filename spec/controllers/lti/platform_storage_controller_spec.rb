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

describe Lti::PlatformStorageController do
  describe "#post_message_forwarding" do
    subject { get :post_message_forwarding }

    before do
      Account.site_admin.enable_feature!(:lti_platform_storage)
    end

    let(:forwarding_domain) { "localhost" }

    context "with lti_platform_storage flag off" do
      before do
        Account.site_admin.disable_feature!(:lti_platform_storage)
      end

      it { is_expected.to be_not_found }
    end

    before do
      allow(CanvasSecurity).to receive(:config).and_return({ "lti_iss" => forwarding_domain })
    end

    it "sets parent origin in js env" do
      subject
      expect(assigns.dig(:js_env, :PARENT_ORIGIN)).to match(forwarding_domain)
    end

    it { is_expected.to be_successful }

    it "modifies the frame-ancestors in the CSP header" do
      subject
      expect(response.headers["Content-Security-Policy"])
        .to match(/frame-ancestors [^;]*self[^;]*localhost/)
    end

    it "caches the response" do
      subject
      expect(response.headers["Cache-Control"]).to match(/max-age=#{1.day.seconds}/)
    end
  end
end
