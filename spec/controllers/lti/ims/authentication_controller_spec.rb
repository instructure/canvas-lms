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

require_relative "../../../lti_1_3_spec_helper"
require_relative "../concerns/parent_frame_shared_examples"

describe Lti::IMS::AuthenticationController do
  include Lti::RedisMessageClient

  let(:developer_key) do
    key = DeveloperKey.create!(
      redirect_uris:,
      account: context.root_account
    )
    enable_developer_key_account_binding!(key)
    key
  end
  let(:redirect_uris) { ["https://redirect.tool.com"] }
  let(:user) { user_model }
  let(:redirect_domain) { "redirect.instructure.com" }
  let(:verifier) { SecureRandom.hex 64 }
  let(:client_id) { developer_key.global_id }
  let(:context) { account_model }
  let(:login_hint) { Lti::Asset.opaque_identifier_for(user, context:) }
  let(:nonce) { SecureRandom.uuid }
  let(:prompt) { "none" }
  let(:redirect_uri) { "https://redirect.tool.com?foo=bar" }
  let(:response_mode) { "form_post" }
  let(:response_type) { "id_token" }
  let(:scope) { "openid" }
  let(:state) { SecureRandom.uuid }
  let(:include_storage_target) { true }
  let(:lti_message_hint_jwt_params) do
    {
      verifier:,
      canvas_domain: redirect_domain,
      context_id: context.global_id,
      context_type: context.class.to_s,
      include_storage_target:
    }
  end
  let(:lti_message_hint) do
    Canvas::Security.create_jwt(lti_message_hint_jwt_params, 1.year.from_now)
  end
  let(:params) do
    {
      "client_id" => client_id.to_s,
      "login_hint" => login_hint,
      "nonce" => nonce,
      "prompt" => prompt,
      "redirect_uri" => redirect_uri,
      "response_mode" => response_mode,
      "response_type" => response_type,
      "scope" => scope,
      "state" => state,
      "lti_message_hint" => lti_message_hint
    }
  end

  before { user_session(user) }

  describe "authorize_redirect" do
    context "when authorization request has no errors" do
      subject do
        post(:authorize_redirect, params:)
        URI.parse(response.headers["Location"])
      end

      it "redirects to the domain in the lti_message_hint" do
        expect(subject.host).to eq "redirect.instructure.com"
      end

      it "redirects the the authorization endpoint" do
        expect(subject.path).to eq "/api/lti/authorize"
      end

      it "forwards all oidc params" do
        sent_params = Rack::Utils.parse_nested_query(subject.query)
        expect(sent_params).to eq params
      end
    end

    shared_examples_for "lti_message_hint error" do
      it { is_expected.to be_bad_request }

      it "has a descriptive error message" do
        expect(JSON.parse(subject.body)["message"]).to eq "Invalid lti_message_hint"
      end
    end

    context "when the authorization request has errors" do
      subject do
        post(:authorize_redirect, params:)
        response
      end

      context "when the lti_message_hint is not a JWT" do
        let(:lti_message_hint) { "Not a JWT" }

        it_behaves_like "lti_message_hint error"
      end

      context "when the lti_message_hint is expired" do
        let(:lti_message_hint) do
          Canvas::Security.create_jwt(
            {
              verifier:,
              canvas_domain: redirect_domain
            },
            1.year.ago
          )
        end

        it_behaves_like "lti_message_hint error"
      end

      context "when the lti_message_hint sig is invalid" do
        let(:lti_message_hint) do
          jws = Canvas::Security.create_jwt(
            {
              verifier:,
              canvas_domain: redirect_domain
            },
            1.year.from_now
          )
          jws[0...-1]
        end

        it_behaves_like "lti_message_hint error"
      end
    end
  end

  describe "authorize" do
    subject(:authorize) do
      get :authorize, params:
    end

    shared_examples_for "redirect_uri errors" do
      let(:expected_status) { 400 }

      it { is_expected.to have_http_status(expected_status) }

      it "avoids rendering the redirect_uri form" do
        expect(authorize).not_to render_template("lti/ims/authentication/authorize")
      end
    end

    shared_examples_for "non redirect_uri errors" do
      let(:expected_message) { raise "set in example" }
      let(:expected_error) { raise "set in example" }

      let(:error_object) do
        authorize
        assigns[:oidc_error]
      end

      it { is_expected.to be_successful }

      it "has a descriptive error message" do
        expect(error_object[:error_description]).to eq expected_message
      end

      it "sends the state" do
        expect(error_object[:state]).to eq state
      end

      it "has the correct error code" do
        expect(error_object[:error]).to eq expected_error
      end

      it "renders the redirect_uri_form" do
        expect(authorize).to render_template("lti/ims/authentication/authorize")
      end
    end

    context "when there is a cached LTI 1.3 launch" do
      def authorize
        get :authorize, params:
      end

      include_context "lti_1_3_spec_helper"

      let(:id_token) do
        token = assigns.dig(:id_token, :id_token)
        if token.present?
          JSON::JWT.decode(token, :skip_verification)
        else
          token
        end
      end

      let(:account) { context.root_account }
      let(:lti_launch) do
        {
          "aud" => developer_key.global_id,
          "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => "265:37750cbd4487fb044c4faf195c195b5fb9ed9636",
          "iss" => "https://canvas.instructure.com",
          "nonce" => "a854dc79-be3b-476a-b0db-2963a7f4158c",
          "sub" => "535fa085f22b4655f48cd5a36a9215f64c062838",
          "picture" => "http://canvas.instructure.com/images/messages/avatar-50.png",
          "email" => "wdransfield@instructure.com",
          "name" => "wdransfield@instructure.com",
          "given_name" => "wdransfield@instructure.com",
        }
      end
      let(:verifier) { cache_launch(lti_launch, context) }

      before do
        developer_key.update!(redirect_uris: ["https://redirect.tool.com"])
        enable_developer_key_account_binding!(developer_key)
      end

      it "correctly sets the nonce of the launch" do
        authorize
        expect(id_token["nonce"]).to eq nonce
      end

      it "generates an id token" do
        authorize
        expect(id_token.except("nonce")).to eq lti_launch.except("nonce")
      end

      it "sends the state" do
        authorize
        expect(assigns.dig(:launch_parameters, :state)).to eq state
      end

      it "sends the lti_storage_target" do
        authorize
        expect(assigns.dig(:launch_parameters, :lti_storage_target)).to eq Lti::PlatformStorage::FORWARDING_TARGET
      end

      context "when include_storage_target is false" do
        let(:include_storage_target) { false }

        it "does not send the lti_storage_target" do
          authorize
          expect(assigns[:launch_parameters].keys).not_to include(:lti_storage_target)
        end
      end

      context "when there are additional query params on the redirect_uri" do
        let(:redirect_uris) { ["https://redirect.tool.com?must_be_present=true"] }
        let(:redirect_uri) { "https://redirect.tool.com?must_be_present=true&foo=bar" }

        before do
          developer_key.update!(redirect_uris:)
        end

        it "launches succesfully" do
          authorize
          expect(id_token["nonce"]).to eq nonce
        end
      end

      context "when cached launch has expired" do
        before do
          fetch_and_delete_launch(context, verifier)
        end

        it_behaves_like "non redirect_uri errors" do
          let(:expected_message) { "The launch has either expired or already been consumed" }
          let(:expected_error) { "launch_no_longer_valid" }
        end
      end

      context "when there there is no current user" do
        before { remove_user_session }

        context "when the lti_login_required_error_page feature flag is enabled" do
          before(:once) do
            Account.site_admin.enable_feature!(:lti_login_required_error_page)
          end

          it "renders a friendly error message" do
            authorize
            expect(response).to have_http_status :unauthorized
            expect(response).to render_template("lti/ims/authentication/login_required_error_screen")
          end

          it "increments the lti.oidc_login_required_error metric" do
            allow(InstStatsd::Statsd).to receive(:increment)
            authorize
            expect(InstStatsd::Statsd).to have_received(:increment).with("lti.oidc_login_required_error", tags: {
                                                                           account: context.global_id,
                                                                           client_id: client_id.to_s
                                                                         })
          end
        end

        context "when the lti_login_required_error_page feature flag is disabled" do
          before(:once) do
            Account.site_admin.disable_feature!(:lti_login_required_error_page)
          end

          it_behaves_like "non redirect_uri errors" do
            def authorize
              get :authorize, params:
            end

            let(:expected_message) { "Must have an active user session" }
            let(:expected_error) { "login_required" }
          end

          it "does not render a friendly error message" do
            authorize
            expect(response).to have_http_status :ok
            expect(response).not_to render_template("lti/ims/authentication/login_required_error_screen")
          end
        end

        context "and the context is public" do
          let(:context) do
            course = course_model
            course.update!(is_public: true)
            course.offer
            course
          end

          it "generates an id token" do
            authorize
            expect(id_token.except("nonce")).to eq lti_launch.except("nonce")
          end
        end
      end

      it_behaves_like "an endpoint which uses parent_frame_context to set the CSP header" do
        # The shared examples require `authorize` to make the request -- this is
        # already set up above in the parent rspec context

        # Make sure user has access in the PFC tool (enrollment in tool's course)
        let(:enrollment) { course_with_teacher(user:, active_all: true) }
        let(:pfc_tool_context) { enrollment.course }

        let(:lti_message_hint) do
          Canvas::Security.create_jwt(
            {
              verifier:,
              canvas_domain: redirect_domain,
              context_id: context.global_id,
              context_type: context.class.to_s,
              parent_frame_context: pfc_tool.id.to_s
            },
            1.year.from_now
          )
        end
      end
    end

    context "when there are non redirect_uri errors" do
      context "when there are missing oidc params" do
        let(:params) do
          {
            "client_id" => client_id.to_s,
            "login_hint" => login_hint,
            "redirect_uri" => redirect_uri,
            "response_mode" => response_mode,
            "response_type" => response_type,
            "scope" => scope,
            "state" => state,
            "lti_message_hint" => lti_message_hint
          }
        end

        it_behaves_like "non redirect_uri errors" do
          let(:expected_message) { "The following parameters are missing: nonce,prompt" }
          let(:expected_error) { "invalid_request_object" }
        end
      end

      context "when the scope is invalid" do
        let(:scope) { "banana" }

        it_behaves_like "non redirect_uri errors" do
          let(:expected_message) { "The 'scope' must be 'openid'" }
          let(:expected_error) { "invalid_request_object" }
        end
      end

      context "when the current user is not in the login_hint" do
        let(:login_hint) { "not_the_correct_lti_id" }

        it_behaves_like "non redirect_uri errors" do
          let(:expected_message) { "Must have an active user session" }
          let(:expected_error) { "login_required" }
        end
      end

      context "when the developer key is not active" do
        before { developer_key.update!(workflow_state: "inactive") }

        it_behaves_like "non redirect_uri errors" do
          let(:expected_message) { "Client not authorized in requested context" }
          let(:expected_error) { "unauthorized_client" }
        end
      end

      context "when key has no bindings to the context" do
        before do
          developer_key.developer_key_account_bindings.destroy_all
        end

        it_behaves_like "non redirect_uri errors" do
          let(:expected_message) { "Client not authorized in requested context" }
          let(:expected_error) { "unauthorized_client" }
        end
      end
    end

    context "when the developer key redirect uri does not match" do
      before { developer_key.update!(redirect_uris: ["https://www.not-matching.com"]) }

      it_behaves_like "redirect_uri errors" do
        let(:expected_message) { "Invalid redirect_uri" }
      end
    end

    context "when the developer key redirect uri contains a query string" do
      let(:redirect_uris) { ["https://redirect.tool.com?must_be_present=true"] }

      it_behaves_like "redirect_uri errors" do
        let(:expected_message) { "Invalid redirect_uri" }
      end
    end

    context "when the developer key does not exist" do
      let(:client_id) { developer_key.global_id + 100 }

      it_behaves_like "redirect_uri errors" do
        let(:expected_message) { nil }
        let(:expected_status) { 404 }
      end
    end
  end
end
