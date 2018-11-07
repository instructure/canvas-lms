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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../lti_1_3_spec_helper')

RSpec.describe Lti::ToolConfigurationsApiController, type: :controller do
  include_context 'lti_1_3_spec_helper'

  subject { response }
  let_once(:sub_account) { account_model(root_account: account) }
  let_once(:admin) { account_admin_user(account: account) }
  let_once(:student) do
    student_in_course
    @student
  end
  let(:config_from_response) do
    Lti::ToolConfiguration.find(json_parse.dig('tool_configuration', 'id'))
  end
  let_once(:account) { Account.default }
  let(:dev_key_params) do
    {
      name: "Test Dev Key",
      email: "test@test.com",
      notes: "Some cool notes",
      test_cluster_only: true,
      scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
      require_scopes: true,
      redirect_uris: "http://www.test.com\r\nhttp://www.anothertest.com"
    }
  end
  let(:new_url) { 'https://www.new-url.com/test' }
  let(:dev_key_id) { developer_key.id }
  let(:valid_parameters) do
    {
      developer_key: dev_key_params,
      account_id: sub_account.id,
      developer_key_id: dev_key_id,
      tool_configuration: {
        settings: settings
      }
    }.compact
  end
  let(:invalid_parameters) do
    {
      developer_key_id: dev_key_id,
      account_id: sub_account.id,
      developer_key: dev_key_params,
      tool_configuration: {
        settings: invalid_settings
      }
    }
  end

  let(:invalid_settings) { settings.merge({ 'public_jwk' => invalid_public_jwk }) }

  before { user_session(admin) }

  shared_examples_for 'an action that requires manage developer keys' do |skip_404|
    context 'when the user has manage_developer_keys' do
      it { is_expected.to be_success }
    end

    context 'when the user is not an admin' do
      before { user_session(student) }

      it { is_expected.to be_unauthorized }
    end

    unless skip_404
      context 'when the developer key does not exist' do
        before { developer_key.destroy! }

        it { is_expected.to be_not_found }
      end
    end
  end

  shared_examples_for 'an endpoint that requires an existing tool configuration' do
    context 'when the tool configuration does not exist' do
      it { is_expected.to be_not_found }
    end
  end

  shared_examples_for 'an endpoint that accepts a settings_url' do
    let(:ok_response) do
      double(
        body: settings.to_json,
        is_a?: true,
        '[]' => 'application/json'
      )
    end
    let(:url) { 'https://www.mytool.com/config/json' }
    let(:valid_parameters) do
      {
        developer_key: dev_key_params,
        account_id: sub_account.id,
        developer_key_id: developer_key.id,
        tool_configuration: {
          settings_url: url,
          disabled_placements: ['course_navigation', 'account_navigation'],
          custom_fields: "foo=bar\r\nkey=value"
        }
      }
    end
    let(:make_request) { raise 'Override in spec' }

    context 'when the request does not time out' do
      before do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(ok_response)
      end

      it 'uses the tool configuration JSON from the settings_url' do
        subject
        expect(config_from_response.settings['launch_url']).to eq settings['launch_url']
      end

      it 'sets the "disabled_placements"' do
        subject
        expect(config_from_response.disabled_placements).to match_array(
          valid_parameters.dig(:tool_configuration, :disabled_placements)
        )
      end

      it 'sets the "custom_fields"' do
        subject
        expect(config_from_response.custom_fields).to eq valid_parameters.dig(:tool_configuration, :custom_fields)
      end
    end

    context 'when the request times out' do
      before do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Timeout::Error)
      end

      it { is_expected.to have_http_status :unprocessable_entity }

      it 'responds with helpful error message' do
        subject
        expect(json_parse['errors'].first['message']).to eq 'Could not retrieve settings, the server response timed out.'
      end
    end

    context 'when the response is not a success' do
      subject { json_parse['errors'].first['message'] }

      let(:stubbed_response) { double() }

      before do
        allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return false
        allow(stubbed_response).to receive('[]').and_return('application/json')
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(stubbed_response)
      end

      context 'when the response is "not found"' do
        before do
          allow(stubbed_response).to receive(:message).and_return('Not found')
          allow(stubbed_response).to receive(:code).and_return('404')
          make_request
        end

        it { is_expected.to eq 'Not found' }
      end

      context 'when the response is "unauthorized"' do
        before do
          allow(stubbed_response).to receive(:message).and_return('Unauthorized')
          allow(stubbed_response).to receive(:code).and_return('401')
          make_request
        end

        it { is_expected.to eq 'Unauthorized' }
      end

      context 'when the response is "internal server error"' do
        before do
          allow(stubbed_response).to receive(:message).and_return('Internal server error')
          allow(stubbed_response).to receive(:code).and_return('500')
          make_request
        end

        it { is_expected.to eq 'Internal server error' }
      end

      context 'when the response is not JSON' do
        before do
          allow(stubbed_response).to receive('[]').and_return('text/html')
          allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return true
          make_request
        end

        it { is_expected.to eq 'Content type must be "application/json"' }
      end
    end
  end

  shared_examples_for 'an endpoint that accepts developer key parameters' do
    subject do
      make_request
      DeveloperKey.find(json_parse.dig('developer_key', 'id'))
    end

    let(:make_request) { raise 'set in example' }
    let(:bad_scope_request) { raise 'set in example' }

    it 'sets the developer key name' do
      expect(subject.name).to eq dev_key_params[:name]
    end

    it 'sets the developer key email' do
      expect(subject.email).to eq dev_key_params[:email]
    end

    it 'sets the developer key notes' do
      expect(subject.notes).to eq dev_key_params[:notes]
    end

    it 'sets the developer key test_cluster_only' do
      expect(subject.test_cluster_only).to eq dev_key_params[:test_cluster_only]
    end

    it 'sets the developer key scopes' do
      expect(subject.scopes).to eq dev_key_params[:scopes]
    end

    it 'sets the developer key require_scopes' do
      expect(subject.require_scopes).to eq dev_key_params[:require_scopes]
    end

    it 'sets the developer key redirect_uris' do
      expect(subject.redirect_uris).to eq dev_key_params[:redirect_uris].split
    end

    context 'when scopes are invalid' do
      subject do
        bad_scope_request
        json_parse['errors'].first['message']
      end

      it { is_expected.to eq 'cannot contain invalid scope' }
    end
  end

  shared_examples_for 'an endpoint that validates public_jwk' do
    let(:make_request) { raise 'set in examples' }

    subject do
      make_request
      json_parse['errors'].first['message']
    end

    context 'when the public jwk is missing' do
      let(:invalid_public_jwk) { nil }

      it { is_expected.to eq '"public_jwk" must be present' }
    end

    context 'when the public jwk is missing keys' do
      let(:invalid_public_jwk) do
        {
          "e" => "AQAB",
          "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
          "kid" => "2018-09-18T21:55:18Z"
        }
      end

      it { is_expected.to eq 'The following fields are required: kty, e, n, kid, alg, use' }
    end

    context 'when the public jwk has an invalid alg' do
      let(:invalid_public_jwk) do
        {
          "kty" => "RSA",
          "e" => "AQAB",
          "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
          "kid" => "2018-09-18T21:55:18Z",
          "alg" => "invalid",
          "use" => "sig"
        }
      end

      it { is_expected.to eq "invalid /alg. Schema: {\"type\"=>\"string\", \"const\"=>\"RS256\"}" }
    end

    context 'when the public jwk has an invalid kty' do
      let(:invalid_public_jwk) do
        {
          "kty" => "invalid",
          "e" => "AQAB",
          "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
          "kid" => "2018-09-18T21:55:18Z",
          "alg" => "RS256",
          "use" => "sig"
        }
      end

      it { is_expected.to eq "invalid /kty. Schema: {\"type\"=>\"string\", \"const\"=>\"RSA\"}" }
    end
  end

  describe '#create' do
    subject { post :create, params: valid_parameters }
    let(:dev_key_id) { nil }

    it_behaves_like 'an action that requires manage developer keys', true

    context 'when the tool configuration does not exist' do
      let(:dev_key_id) { developer_key.id }

      it { is_expected.to be_ok }

      it 'creates a developer key on the correct account' do
        subject
        key = DeveloperKey.find(json_parse.dig('tool_configuration', 'developer_key_id'))
        expect(key.account).to eq sub_account
      end
    end

    it_behaves_like 'an endpoint that accepts a settings_url' do
      let(:make_request) { post :create, params: valid_parameters }
    end

    it_behaves_like 'an endpoint that validates public_jwk' do
      let(:make_request) { post :create, params: invalid_parameters }
    end

    it_behaves_like 'an endpoint that accepts developer key parameters' do
      let(:bad_scope_params) {{ account_id: sub_account.id, developer_key: dev_key_params.merge(scopes: ['invalid scope']) }}
      let(:make_request) { post :create, params: valid_parameters.merge({developer_key: dev_key_params}) }
      let(:bad_scope_request) { post :create, params: valid_parameters.merge(bad_scope_params) }
    end
  end

  describe '#update' do
    subject { put :update, params: valid_parameters }

    let(:launch_url) { new_url }

    before do
      tool_configuration
    end

    context do
      it { is_expected.to be_ok }

      it 'updates the tool configuration' do
        subject
        new_settings = config_from_response.settings
        expect(new_settings['launch_url']).to eq new_url
      end
    end

    it_behaves_like 'an endpoint that accepts a settings_url' do
      let(:make_request) { post :update, params: valid_parameters }
    end

    it_behaves_like 'an endpoint that validates public_jwk' do
      let(:make_request) { put :update, params: invalid_parameters }
    end

    it_behaves_like 'an action that requires manage developer keys'

    it_behaves_like 'an endpoint that accepts developer key parameters' do
      let(:bad_scope_params) {{ developer_key: dev_key_params.merge(scopes: ['invalid scope']) }}
      let(:make_request) { put :update, params: valid_parameters.merge({developer_key: dev_key_params}) }
      let(:bad_scope_request) { put :update, params: valid_parameters.merge(bad_scope_params) }
    end
  end

  describe '#show' do
    subject { get :show, params: valid_parameters.except(:tool_configuration) }

    before do
      tool_configuration
    end

    it_behaves_like 'an action that requires manage developer keys'

    context do
      let(:tool_configuration) { nil }
      it_behaves_like 'an endpoint that requires an existing tool configuration'
    end

    context 'when the tool configuration exists' do
      it 'renders the tool configuration' do
        subject
        expect(config_from_response).to eq tool_configuration
      end
    end
  end

  describe '#destroy' do
    subject {  delete :destroy, params: valid_parameters.except(:tool_configuration) }

    before do
      tool_configuration
    end

    it_behaves_like 'an action that requires manage developer keys'

    context do
      let(:tool_configuration) { nil }
      it_behaves_like 'an endpoint that requires an existing tool configuration'
    end

    context 'when the tool configuration exists' do
      it 'destroys the tool configuration' do
        subject
        expect(Lti::ToolConfiguration.find_by(id: tool_configuration.id)).to be_nil
      end

      it { is_expected.to be_no_content }
    end
  end
end
