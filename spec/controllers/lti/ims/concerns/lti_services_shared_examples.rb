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
#

shared_examples "mime_type check" do
  it "does not return ims mime_type" do
    expect(response.headers["Content-Type"]).not_to include expected_mime_type
  end
end

shared_examples_for "lti services" do
  let(:extra_tool_context) { raise "Override in spec" }

  shared_examples "extra developer key and account tool check" do
    let(:extra_tool_context) { course_account }

    it_behaves_like "extra developer key and tool check"
  end

  shared_examples "extra developer key and course tool check" do
    let(:extra_tool_context) { course }

    it_behaves_like "extra developer key and tool check"
  end

  shared_examples "extra developer key and tool check" do
    context "a account chain-reachable tool is associated with a different developer key" do
      let(:developer_key_that_should_not_be_resolved_from_request) { DeveloperKey.create!(account: developer_key.account) }
      let(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: extra_tool_context,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool 2",
          url: "http://www.tool2.com/launch",
          developer_key: developer_key_that_should_not_be_resolved_from_request,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      context "and that developer key is the only developer key" do
        let(:before_send_request) { -> { developer_key.destroy! } }

        it_behaves_like "mime_type check"

        it "returns 401 unauthorized and complains about missing developer key" do
          expect(response).to have_http_status :unauthorized
          expect(json).to be_lti_advantage_error_response_body("unauthorized", "Unknown or inactive Developer Key")
        end
      end
    end
  end

  describe "common lti advantage request and response check" do
    # #around and #before(:context) don't have access to the right scope, #before(:example) runs too late,
    # so hack our own lifecycle hook
    let(:before_send_request) { -> {} }

    before do
      before_send_request.call
      send_request
    end

    it "returns correct mime_type" do
      expect(response.headers["Content-Type"]).to include expected_mime_type
    end

    it "returns 200 success" do
      expect(response).to have_http_status http_success_status
    end

    context "with site admin developer key" do
      context "when LTI 1.3 feature is allowed" do
        let(:before_send_request) do
          lambda do
            developer_key.update!(account: nil)
          end
        end

        it "returns 200 success" do
          expect(response).to have_http_status http_success_status
        end
      end
    end

    context 'with "canvas.instructure.com" aud' do
      let(:universal_grant_host) { "http://canvas.instructure.com/login/oauth2/token" }
      let(:access_token_jwt_hash) { super().merge(aud: universal_grant_host) }

      it "returns 200 success" do
        expect(response).to have_http_status http_success_status
      end
    end

    context "with correct token but also a normandy_session" do
      let(:before_send_request) do
        lambda do
          allow(controller).to receive(:verify_authenticity_token).and_call_original
        end
      end

      it "skips authenticity check and returns 200 success" do
        expect(response).to have_http_status http_success_status
        expect(controller).not_to have_received(:verify_authenticity_token)
      end
    end

    context "with system failure during access token validation" do
      let(:jwt_validator) { instance_double(Canvas::Security::JwtValidator) }
      let(:before_send_request) do
        lambda do
          allow(Canvas::Security::JwtValidator).to receive(:new).and_return(jwt_validator)
          expect(jwt_validator).to receive(:valid?).and_raise(StandardError)
        end
      end

      it_behaves_like "mime_type check"

      it "returns 500 not found" do
        expect(response).to have_http_status :internal_server_error
      end
    end

    context "with no access token" do
      let(:access_token_jwt_hash) { nil }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing access token" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Missing access token")
      end
    end

    context "with malformed access token" do
      let(:access_token_jwt) { "gibberish" }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing access token" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Invalid access token format")
      end
    end

    context "with no access token scope grant" do
      let(:access_token_scopes) do
        remove_access_token_scope(super(), scope_to_remove)
      end

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing scope" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Insufficient permissions")
      end
    end

    context "with invalid access token signature" do
      let(:access_token_signing_key) { CanvasSlug.generate(nil, 64) }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about an incorrect signature" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Access token invalid - signature likely incorrect")
      end
    end

    context "with missing access token claims" do
      let(:access_token_jwt_hash) { super().delete_if { |k| %i[sub aud exp iat jti iss].include?(k) } }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing assertions" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body(
          "unauthorized",
          "Invalid access token field/s: the following assertions are missing: sub,aud,exp,iat,jti,iss"
        )
      end
    end

    context "with invalid access token audience ('aud')" do
      let(:access_token_jwt_hash) { super().merge(aud: "https://wont/match/anything") }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about an invalid aud field" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Invalid access token field/s: the 'aud' is invalid")
      end
    end

    context "with expired access token" do
      let(:access_token_jwt_hash) { super().merge(exp: (Time.zone.now.to_i - 1.hour.to_i)) }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about an expired access token" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Access token expired")
      end
    end

    context "with access token issuance timestamp in the future ('iat')" do
      let(:access_token_jwt_hash) { super().merge(iat: (Time.zone.now.to_i + 1.hour.to_i)) }

      it "returns 401 unauthorized and complains about an invalid iat field" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Invalid access token field/s: the 'iat' must not be in the future")
      end
    end

    context "whith access token issuance timestamp more than an hour old" do
      let(:access_token_jwt_hash) { super().merge(iat: (Time.zone.now.to_i - 2.hours.to_i)) }

      it "returns 401 unauthorized and complains about an invalid iat field" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Invalid access token field/s: the 'iat' must be less than 3600 seconds old")
      end
    end

    context "with inactive developer key" do
      let(:before_send_request) do
        lambda do
          developer_key.workflow_state = :inactive
          developer_key.save!
        end
      end

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing developer key" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Unknown or inactive Developer Key")
      end
    end

    context "with deleted developer key" do
      let(:before_send_request) { -> { developer_key.destroy! } }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing developer key" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Unknown or inactive Developer Key")
      end
    end

    it_behaves_like "extra developer key and account tool check"
    it_behaves_like "extra developer key and course tool check"
  end
end
