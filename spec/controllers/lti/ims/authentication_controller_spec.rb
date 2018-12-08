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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lti_1_3_spec_helper')

describe Lti::Ims::AuthenticationController do
  include Lti::RedisMessageClient

  let(:developer_key) {
    key = DeveloperKey.create!(
      redirect_uris: ['https://redirect.tool.com'],
      account: context
    )
    enable_developer_key_account_binding!(key)
    key
  }
  let(:user) { user_model }
  let(:redirect_domain) { 'redirect.instructure.com' }
  let(:verifier) { SecureRandom.hex 64 }
  let(:client_id) { developer_key.global_id }
  let(:context) { account_model }
  let(:login_hint) { Lti::Asset.opaque_identifier_for(user) }
  let(:nonce) { SecureRandom.uuid }
  let(:prompt) { 'none' }
  let(:redirect_uri) { 'https://redirect.tool.com?foo=bar' }
  let(:response_mode) { 'form_post' }
  let(:response_type) { 'id_token' }
  let(:scope) { 'openid' }
  let(:state) { SecureRandom.uuid }
  let(:lti_message_hint) do
    Canvas::Security.create_jwt(
      {
        verifier: verifier,
        canvas_domain: redirect_domain,
        context_id: context.global_id,
        context_type: context.class.to_s
      },
      1.year.from_now
    )
  end
  let(:params) do
    {
      'client_id' => client_id.to_s,
      'login_hint' => login_hint,
      'nonce' => nonce,
      'prompt' => prompt,
      'redirect_uri' => redirect_uri,
      'response_mode' => response_mode,
      'response_type' => response_type,
      'scope' => scope,
      'state' => state,
      'lti_message_hint' => lti_message_hint
    }
  end

  before { user_session(user) }

  describe 'authorize_redirect' do
    before { post :authorize_redirect, params: params }

    context 'when authorization request has no errors' do
      subject { URI.parse(response.headers['Location']) }

      it 'redirects to the domain in the lti_message_hint' do
        expect(subject.host).to eq 'redirect.instructure.com'
      end

      it 'redirects the the authorization endpoint' do
        expect(subject.path).to eq '/api/lti/authorize'
      end

      it 'forwards all oidc params' do
        sent_params = Rack::Utils.parse_nested_query(subject.query)
        expect(sent_params).to eq params
      end
    end

    shared_examples_for 'lti_message_hint error' do
      it { is_expected.to be_bad_request }

      it 'has a descriptive error message' do
        expect(JSON.parse(subject.body)['message']).to eq 'Invalid lti_message_hint'
      end
    end

    context 'when the authorization request has errors' do
      subject { response }

      context 'when the lti_message_hint is not a JWT' do
        let(:lti_message_hint) { 'Not a JWT' }

        it_behaves_like 'lti_message_hint error'
      end

      context 'when the lti_message_hint is expired' do
        let(:lti_message_hint) do
          Canvas::Security.create_jwt(
            {
              verifier: verifier,
              canvas_domain: redirect_domain
            },
            1.year.ago
          )
        end

        it_behaves_like 'lti_message_hint error'
      end

      context 'when the lti_message_hint sig is invalid' do
        let(:lti_message_hint) do
          jws = Canvas::Security.create_jwt(
            {
              verifier: verifier,
              canvas_domain: redirect_domain
            },
            (1.year.from_now)
          )
          jws.first(-1)
        end

        it_behaves_like 'lti_message_hint error'
      end
    end
  end

  describe 'authorize' do
    subject { get :authorize, params: params }

    shared_examples_for 'redirect_uri errors' do
      let(:expected_status) { 400 }

      it { is_expected.to have_http_status(expected_status) }
    end

    shared_examples_for 'non redirect_uri errors' do
      let(:expected_message) { raise 'set in example' }
      let(:expected_error) { raise 'set in example' }
      let(:error_object) do
        subject
        assigns[:oidc_error]
      end

      it { is_expected.to be_success }

      it 'has a descriptive error message' do
        expect(error_object[:error_description]).to eq expected_message
      end

      it 'sends the state' do
        expect(error_object[:state]).to eq state
      end

      it 'has the correct error code' do
        expect(error_object[:error]).to eq expected_error
      end
    end

    context 'when there is a cached LTI 1.3 launch' do
      include_context 'lti_1_3_spec_helper'

      subject do
        get :authorize, params: params
        JSON::JWT.decode(assigns.dig(:id_token, :id_token), :skip_verification)
      end

      let(:account) { context }
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
        developer_key.update!(redirect_uris: ['https://redirect.tool.com'])
        enable_developer_key_account_binding!(developer_key)
      end

      it 'correctly sets the nonce of the launch' do
        expect(subject['nonce']).to eq nonce
      end

      it 'generates an id token' do
        expect(subject.except('nonce')).to eq lti_launch.except('nonce')
      end

      it 'sends the state' do
        subject
        expect(assigns.dig(:id_token, :state)).to eq state
      end
    end

    context 'when there are non redirect_uri errors' do
      context 'when there are missing oidc params' do
        let(:params) do
          {
            'client_id' => client_id.to_s,
            'login_hint' => login_hint,
            'redirect_uri' => redirect_uri,
            'response_mode' => response_mode,
            'response_type' => response_type,
            'scope' => scope,
            'state' => state,
            'lti_message_hint' => lti_message_hint
          }
        end

        it_behaves_like 'non redirect_uri errors' do
          let(:expected_message) { "The following parameters are missing: nonce,prompt" }
          let(:expected_error) { "invalid_request_object" }
        end
      end

      context 'when the scope is invalid' do
        let(:scope) { 'banana' }

        it_behaves_like 'non redirect_uri errors' do
          let(:expected_message) { "The 'scope' must be 'openid'" }
          let(:expected_error) { "invalid_request_object" }
        end
      end

      context 'when the current user is not in the login_hint' do
        let(:login_hint) { 'not_the_correct_lti_id' }

        it_behaves_like 'non redirect_uri errors' do
          let(:expected_message) { "The user is not logged in" }
          let(:expected_error) { "login_required" }
        end
      end

      context 'when the devloper key is not active' do
        before { developer_key.update!(workflow_state: 'inactive') }

        it_behaves_like 'non redirect_uri errors' do
          let(:expected_message) { "Client not authorized in requested context" }
          let(:expected_error) { "unauthorized_client" }
        end
      end
    end

    context 'when the developer key redirect uri does not match' do
      before { developer_key.update!(redirect_uris: ['https://www.not-matching.com']) }

      it_behaves_like 'redirect_uri errors' do
        let(:expected_message) { 'Invalid redirect_uri' }
      end
    end

    context 'when the developer key does not exist' do
      let(:client_id) { developer_key.global_id + 100 }

      it_behaves_like 'redirect_uri errors' do
        let(:expected_message) { nil }
        let(:expected_status) { 404 }
      end
    end
  end
end