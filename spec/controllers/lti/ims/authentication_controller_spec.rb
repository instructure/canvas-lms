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

describe Lti::Ims::AuthenticationController do
  let(:developer_key) { DeveloperKey.create!(redirect_uris: ['https://redirect.tool.com']) }
  let(:user) { user_model }
  let(:redirect_domain) { 'redirect.instructure.com' }
  let(:verifier) { SecureRandom.hex 64 }
  let(:client_id) { developer_key.global_id }
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
        canvas_domain: redirect_domain
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
      let(:expected_message) { raise 'set in example' }
      let(:expected_status) { 400 }

      it { is_expected.to have_http_status(expected_status) }

      it 'has a descriptive error message' do
        expect(JSON.parse(subject.body)['message']).to eq expected_message
      end
    end

    context 'when the devloper key is not active' do
      before { developer_key.update!(workflow_state: 'inactive') }

      it_behaves_like 'redirect_uri errors' do
        let(:expected_message) { 'Invalid client_id' }
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