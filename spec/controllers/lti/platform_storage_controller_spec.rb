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

    context "when rendering the view" do
      render_views

      it "sets parent origin in js env" do
        subject
        expected_parent_origin = (HostUrl.protocol + "://" + forwarding_domain).to_json
        expect(response.body).to \
          match(
            %r[<script>\s+window\.ENV = { PARENT_ORIGIN: #{Regexp.escape expected_parent_origin} }\s+</script>]
          )
      end

      it "includes the lti_post_message_forwarding.js script" do
        subject
        expect(response.body).to match(%r{<script src=.*javascripts/lti_post_message_forwarding.*js})
      end
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
