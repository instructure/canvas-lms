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

    let(:forwarding_domain) { "localhost" }

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

    describe ".rev_fingerprint" do
      it "includes the javascript CDN fingerprint" do
        src_file = "javascripts/lti_post_message_forwarding.js"
        dist_file = "/dist/javascripts/lti_post_message_forwarding-abcdef123.js"
        expect(Canvas::Cdn.registry).to receive(:url_for).with(src_file).and_return(dist_file)
        expect(described_class.rev_fingerprint).to include("abcdef123")
      end

      it "includes a fingerprint of the controller and view files" do
        files = [
          described_class.instance_method(:post_message_forwarding).source_location.first,
          Rails.root.join("app/views/lti/platform_storage/post_message_forwarding.html.erb")
        ]
        files_contents = files.map { |f| File.read(f) }.join
        expect(described_class.rev_fingerprint).to include(Digest::SHA256.hexdigest(files_contents)[0...16])
      end
    end
  end
end
