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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../lti_1_3_spec_helper')
require_dependency 'lti/tool_configuration'

module Lti
  describe ToolConfiguration do
    include_context 'lti_1_3_spec_helper'

    let(:public_jwk) do
      {
        "kty" => "RSA",
        "e" => "AQAB",
        "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
        "kid" => "2018-09-18T21:55:18Z",
        "alg" => "RS256",
        "use" => "sig"
      }
    end
    let(:tool_configuration) { described_class.new(settings: settings) }
    let(:developer_key) { DeveloperKey.create }

    describe 'validations' do
      subject { tool_configuration.save }

      context 'when valid' do
        before do
          tool_configuration.developer_key = developer_key
          tool_configuration.disabled_placements = ['account_navigation']
        end

        it { is_expected.to eq true }
      end

      context 'with non-matching schema' do
        let(:settings) do
          s = super()
          s.delete('target_link_uri')
          s
        end

        before do
          tool_configuration.developer_key = developer_key
        end

        it { is_expected.to eq false }

        it 'is contains a message about missing target_link_uri' do
          tool_configuration.valid?
          expect(tool_configuration.errors[:configuration].first.message).to include('target_link_uri,')
        end
      end

      context 'when developer_key already has a tool_config' do
        before do
          described_class.create! settings: settings, developer_key: developer_key
        end

        it { is_expected.to eq false }
      end

      context 'when "settings" is blank' do
        before do
          tool_configuration.developer_key = developer_key
          tool_configuration.settings = nil
        end

        it { is_expected.to eq false }
      end

      context 'when "developer_key_id" is blank' do
        before { tool_configuration.settings = {foo: 'bar'} }

        it { is_expected.to eq false }
      end

      context 'when the settings are invalid' do
        before { tool_configuration.developer_key = developer_key }

        context 'when no URL or domain is set' do
          before do
            settings.delete('target_link_uri')
            settings['extensions'].first.delete('domain')
            settings['extensions'].first.delete('target_link_uri')
            settings['extensions'].first['settings']['placements'].first.delete('target_link_uri')
          end

          it { is_expected.to eq false }
        end

        context 'when name is blank' do
          before { settings.delete('title') }

          it { is_expected.to eq false }
        end
      end

      context 'when "disabled_placements" contains invalid placements' do
        before { tool_configuration.disabled_placements = ['invalid_placement', 'account_navigation'] }

        it { is_expected.to eq false }
      end

      context 'when extensions have non-Canvas platform' do
        let(:settings) do
          sets = super()
          sets['extensions'].first['platform'] = 'blackboard.bb.com'
          sets
        end

        before do
          tool_configuration.developer_key = developer_key
        end

        it { is_expected.to eq true }
      end

      context 'when public_jwk is not present' do
        let (:settings) do
          s = super()
          s.delete('public_jwk')
          s['public_jwk_url'] = "https://test.com"
          s
        end

        before do
          tool_configuration.developer_key = developer_key
        end

        it { is_expected.to eq true }
      end

      context 'when public_jwk_url is not present' do
        let (:settings) do
          s = super()
          s.delete('public_jwk_url')
          s['public_jwk'] = public_jwk
          s
        end

        before do
          tool_configuration.developer_key = developer_key
        end

        it { is_expected.to eq true }
      end

      context 'when public_jwk_url and public_jwk are not present' do
        let (:settings) do
          s = super()
          s.delete('public_jwk_url')
          s.delete('public_jwk')
          s
        end

        before do
          tool_configuration.developer_key = developer_key
        end

        it { is_expected.to eq false }
      end
    end

    describe 'after_update' do
      subject { tool_configuration.update!(changes) }

      before { tool_configuration.update!(developer_key: developer_key) }

      context 'when a change to the settings hash was made' do
        let(:changed_settings) do
          s = settings
          s['title'] = 'new title!'
          s
        end
        let(:changes) { {settings: changed_settings} }

        it 'calls update_external_tools! on the developer key' do
          expect(developer_key).to receive(:update_external_tools!)
          subject
        end
      end

      context 'when a change to the settings hash was not made' do
        let(:changes) { {disabled_placements: []} }

        it 'does not call update_external_tools! on the developer key' do
          expect(developer_key).not_to receive(:update_external_tools!)
          subject
        end
      end
    end

    describe '#new_external_tool' do
      subject{ tool_configuration.new_external_tool(context) }

      let(:extensions) { settings['extensions'].first }

      before do
        tool_configuration.developer_key = developer_key
        extensions['privacy_level'] = 'public'
      end

      shared_examples_for 'a new context external tool' do
        context 'when "disabled_placements" is set' do
          before { tool_configuration.disabled_placements = ['course_navigation'] }

          it 'does not set the disabled placements' do
            expect(subject.settings.keys).not_to include 'course_navigation'
          end

          it 'does set placements that are not disabled' do
            expect(subject.settings.keys).to include 'account_navigation'
          end
        end

        context 'placements in root of settings' do
          let(:settings) do
            s = super()
            s['extensions'].first['settings']['collaboration'] = {
              'message_type' => 'LtiResourceLinkRequest',
              'canvas_icon_class' => 'icon-lti',
              'icon_url' => 'https://static.thenounproject.com/png/131630-211.png',
              'text' => 'LTI 1.3 Test Tool Course Navigation',
              'target_link_uri' =>
              'http://lti13testtool.docker/launch?placement=collaboration',
              'enabled' => true
            }
            s
          end

          it 'removes the placement' do
            expect(subject.settings.keys).not_to include 'collaboration'
          end
        end

        context 'when no privacy level is set' do
          before { extensions['privacy_level'] = nil }

          it 'sets the workflow_state to "anonymous"' do
            expect(subject.workflow_state).to eq 'anonymous'
          end
        end

        it 'sets the correct workflow_state' do
          expect(subject.workflow_state).to eq 'public'
        end

        it 'sets the correct placements' do
          expect(subject.settings.keys).to include 'account_navigation'
          expect(subject.settings.keys).to include 'course_navigation'
        end

        it 'uses the correct launch url' do
          expect(subject.url).to eq settings['target_link_uri']
        end

        it 'uses the correct domain' do
          expect(subject.domain).to eq extensions['domain']
        end

        it 'uses the correct context' do
          expect(subject.context).to eq context
        end

        it 'uses the correct description' do
          expect(subject.description).to eq settings['description']
        end

        it 'uses the correct name' do
          expect(subject.name).to eq settings['title']
        end

        it 'uses the correct top-level custom params' do
          expect(subject.custom_fields).to eq({"has_expansion"=>"$Canvas.user.id", "no_expansion"=>"foo"})
        end

        it 'uses the correct icon url' do
          expect(subject.icon_url).to eq extensions.dig('settings', 'icon_url')
        end

        it 'uses the correct selection height' do
          expect(subject.settings[:selection_height]).to eq extensions.dig('settings', 'selection_height')
        end

        it 'uses the correct selection width' do
          expect(subject.settings[:selection_width]).to eq extensions.dig('settings', 'selection_width')
        end

        it 'uses the correct text' do
          expect(subject.text).to eq extensions.dig('settings', 'text')
        end

        it 'sets the developer key' do
          expect(subject.developer_key).to eq developer_key
        end

        context 'placements' do
          subject{ tool_configuration.new_external_tool(context).settings['course_navigation'] }

          let(:placement_settings) { extensions['settings']['placements'].first }

          it 'uses the correct icon class' do
            expect(subject['canvas_icon_class']).to eq placement_settings['canvas_icon_class']
          end

          it 'uses the correct icon url' do
            expect(subject['icon_url']).to eq placement_settings['icon_url']
          end

          it 'uses the correct message type' do
            expect(subject['message_type']).to eq placement_settings['message_type']
          end

          it 'uses the correct text' do
            expect(subject['text']).to eq placement_settings['text']
          end

          it 'uses the correct target_link_uri' do
            expect(subject['target_link_uri']).to eq placement_settings['target_link_uri']
          end

          it 'uses the correct value for enabled' do
            expect(subject['enabled']).to eq placement_settings['enabled']
          end

          it 'uses the correct custom fields' do
            expect(subject['custom_fields']).to eq placement_settings['custom_fields']
          end
        end

        context 'with non-canvas extensions in settings' do
          subject{ tool_configuration.new_external_tool(context) }

          let(:settings) do
            sets = super()
            sets['extensions'].first['platform'] = 'blackboard.bb.com'
            sets
          end

          it 'does not include any placements defined for non-canvas platform' do
            Lti::ResourcePlacement::PLACEMENTS.each do |p|
              expect(subject.settings[p]).to be_blank
            end
          end
        end
      end

      context 'when context is a cousre' do
        it_behaves_like 'a new context external tool' do
          let(:context) { course_model }
        end
      end

      context 'when context is an account' do
        it_behaves_like 'a new context external tool' do
          let(:context) { account_model }
        end
      end
    end

    describe '#create_tool_config_and_key!' do
      let_once(:account) { Account.create! }
      let(:params) do
        {
          settings: settings.with_indifferent_access
        }
      end
      let(:tool_configuration) { described_class.create_tool_config_and_key!(account, params) }

      it 'creates a dev key' do
        expect { described_class.create_tool_config_and_key! account, params }.to change(DeveloperKey, :count).by(1)
      end

      it 'correctly sets custom_fields' do
        expect(tool_configuration.settings['custom_fields']).to eq settings['custom_fields']
      end

      context 'when the account is site admin' do
        let_once(:account) { Account.site_admin }

        it 'does not set the account on the key' do
          config = described_class.create_tool_config_and_key! account, params
          expect(config.developer_key.account).to be_nil
        end
      end

      context 'when tool_config creation fails' do
        let(:settings) { { tool: 'foo' } }

        it 'does not create dev key' do
          expect(DeveloperKey.where(account: account).count).to eq 0
          expect { described_class.create_tool_config_and_key! account, params }.to raise_error ActiveRecord::RecordInvalid
          expect(DeveloperKey.where(account: account).count).to eq 0
        end
      end

      context 'when settings_url is present' do
        let(:params) do
          {
            settings_url: url
          }
        end
        let(:url) { 'https://www.mytool.com/config/json' }
        let(:stubbed_response) do
          double(
            body: settings.to_json,
            '[]' => 'application/json;',
            is_a?: true
          )
        end

        before do
          allow(CanvasHttp).to receive(:get).and_return(stubbed_response)
        end

        it 'fetches JSON from the URL' do
          expect(tool_configuration.settings['target_link_uri']).to eq settings['target_link_uri']
        end

        context 'when a timeout occurs' do
          before { allow(CanvasHttp).to receive(:get).and_raise(Timeout::Error) }

          it 'raises exception if timeout occurs' do
            expect{ tool_configuration }.to raise_error /Could not retrieve settings, the server response timed out./
          end
        end

        context 'when the response is not a success' do
          let(:stubbed_response) { double() }

          before do
            allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return false
            allow(stubbed_response).to receive('[]').and_return('application/json')
            allow(CanvasHttp).to receive(:get).and_return(stubbed_response)
          end

          context 'when the response is "not found"' do
            before do
              allow(stubbed_response).to receive(:message).and_return('Not found')
              allow(stubbed_response).to receive(:code).and_return('404')
            end

            it 'adds a "not found error to the model' do
              expect{ tool_configuration }.to raise_error /Not found/
            end
          end

          context 'when the response is "unauthorized"' do
            before do
              allow(stubbed_response).to receive(:message).and_return('Unauthorized')
              allow(stubbed_response).to receive(:code).and_return('401')
            end

            it 'adds a "unauthorized error to the model' do
              expect{ tool_configuration }.to raise_error /Unauthorized/
            end
          end

          context 'when the response is "internal server error"' do
            before do
              allow(stubbed_response).to receive(:message).and_return('Internal server error')
              allow(stubbed_response).to receive(:code).and_return('500')
            end

            it 'adds a "internal server error to the model' do
              expect{ tool_configuration }.to raise_error /Internal server error/
            end
          end

          context 'when the response is not JSON' do
            before do
              allow(stubbed_response).to receive('[]').and_return('text/html')
              allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return true
            end

            it 'adds an error to the model' do
              expect{ tool_configuration }.to raise_error /Content type must be \"application\/json\"/
            end
          end
        end
      end
    end
  end
end
