# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe Lti::IMS::AdvantageAccessTokenRequestHelper do
  let(:token) { double(Lti::IMS::AdvantageAccessToken) }
  let(:request) { ActionDispatch::Request.new(Rack::MockRequest.env_for("http://test.host/")) }

  let(:subject_token) { described_class.token(request) }

  context "when the request has a token" do
    before do
      allow(AuthenticationMethods).to receive(:access_token).and_return("fakejwt")
      allow(Lti::IMS::AdvantageAccessToken).to receive(:new).with("fakejwt").and_return(token)
    end

    context "when the request has a good token" do
      before { allow(token).to receive(:validate!).and_return(token) }

      specify ".token() returns the token" do
        expect(described_class.token(request)).to eq(token)
      end

      specify ".token_error() returns nil" do
        expect(described_class.token_error(request)).to be_nil
      end

      it "uses the oauth url for request.host_with_port, and the default grant host(s), as possible audience values" do
        expected_auds = [
          "http://test.host/login/oauth2/token",
          "http://canvas.instructure.com/login/oauth2/token",
          "http://sso.canvaslms.com/login/oauth2/token"
        ]
        described_class.token(request)
        expect(token).to have_received(:validate!).with(expected_auds)
      end
    end

    context "when the request has a bad token" do
      let(:err) { Lti::IMS::AdvantageErrors::AdvantageClientError.new("foo") }

      before do
        allow(token).to receive(:validate!).and_return(token).and_raise(err)
      end

      specify ".token() returns nil" do
        expect(described_class.token(request)).to be_nil
      end

      specify ".token_error() returns an error" do
        expect(described_class.token_error(request)).to eq(err)
      end

      it "caches the result so it doesn't parse the token twice" do
        2.times do
          described_class.token(request)
          described_class.token_error(request)
        end
        expect(Lti::IMS::AdvantageAccessToken).to have_received(:new).exactly(:once)
        expect(token).to have_received(:validate!).exactly(:once)
      end
    end
  end

  context "when the request has no token" do
    let(:err) { Lti::IMS::AdvantageErrors::AdvantageServiceError.new("foo") }

    before { allow(AuthenticationMethods).to receive(:access_token).and_return(nil) }

    specify ".token() returns nil" do
      expect(described_class.token(request)).to be_nil
    end

    specify ".token_error() returns nil" do
      expect(described_class.token_error(request)).to be_nil
    end
  end

  describe ".lti_advantage_route?" do
    def result_for_path(path)
      req = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://test.host/#{path}"))
      described_class.lti_advantage_route?(req)
    end

    it "returns true if the route's controller includes the LtiServices concern" do
      expect(result_for_path("api/lti/courses/123/line_items")).to be(true)
      # Account lookup controller:
      expect(result_for_path("api/lti/accounts/123")).to be(true)
    end

    it "returns false if given a route for a controller that doesn't include LtiServices" do
      expect(result_for_path("api/courses/123")).to be(false)
      expect(result_for_path("api/lti/assignments/1/files/2/originality_report")).to be(false)
      expect(result_for_path("api/lti/security/jwks")).to be(false)
    end

    it "returns false if given a bad route" do
      expect(result_for_path("blablablanonsense-route-doesnexist")).to be(false)
      expect(result_for_path("api/lti/blablabla-wombat123")).to be(false)
    end

    it "returns false if the route references a non-existent controller" do
      # probably wouldn't happen, but it does in the specs, and if it happens I
      # don't want to blow up here in this method
      expect(Rails.application.routes).to receive(:recognize_path)
        .and_return(controller: "oops_this_controller_doesnt/really_exist")
      expect(result_for_path("api/lti/security/jwks")).to be(false)
    end

    specify "there are no routes for controllers which include the LtiServices concern that don't start with /api/lti" do
      # This is an assumption that underlies an optimization in
      # lti_advantage_route? -- we don't parse the route if the request path
      # doesn't start with /api/lti. So all routes that use LtiServices need to
      # start with /api/lti
      Rails.application.routes.routes.each do |r|
        path_spec = r.path.spec.to_s
        next unless r.defaults[:controller]

        begin
          controller = "#{r.defaults[:controller]}_controller".classify.constantize
        rescue NameError
          next
        end

        next unless controller.include?(Lti::IMS::Concerns::LtiServices)

        err_msg = "path #{path_spec.inspect} (controller #{controller.name}) uses " \
                  "LtiServices but path does not start with /api/lti -- optimization in " \
                  "`lti_advantage_route?` will fail"
        expect(path_spec).to start_with("/api/lti/"), err_msg
      end
    end
  end

  describe ".expected_audiences" do
    it "is able to handle multiple universal grant hosts from the configuration" do
      allow(Canvas::Security).to receive(:config).and_return(
        {
          "lti_grant_host" => "canvas.instructure.com,sso.canvaslms.com"
        }
      )

      expect(described_class.expected_audience(request)).to contain_exactly(
        "http://test.host/login/oauth2/token",
        "http://canvas.instructure.com/login/oauth2/token",
        "http://sso.canvaslms.com/login/oauth2/token"
      )
    end
  end
end
