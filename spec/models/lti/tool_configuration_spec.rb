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
require_dependency 'lti/tool_configuration'

module Lti
  describe ToolConfiguration do
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
    let(:settings) do
      {
        'title' => 'LTI 1.3 Tool',
        'description' => '1.3 Tool',
        'public_jwk' => public_jwk,
        'launch_url' => 'http://lti13testtool.docker/blti_launch',
        'custom_fields' => {'has_expansion' => '$Canvas.user.id', 'no_expansion' => 'foo'},
        'extensions' =>  [
          {
            'platform' => 'canvas.instructure.com',
            'privacy_level' => 'public',
            'tool_id' => 'LTI 1.3 Test Tool',
            'domain' => 'http://lti13testtool.docker',
            'settings' =>  {
              'icon_url' => 'https://static.thenounproject.com/png/131630-200.png',
              'selection_height' => 500,
              'selection_width' => 500,
              'text' => 'LTI 1.3 Test Tool Extension text',
              'course_navigation' =>  {
                'message_type' => 'LtiResourceLinkRequest',
                'canvas_icon_class' => 'icon-lti',
                'icon_url' => 'https://static.thenounproject.com/png/131630-211.png',
                'text' => 'LTI 1.3 Test Tool Course Navigation',
                'url' =>
                'http://lti13testtool.docker/launch?placement=course_navigation',
                'enabled' => true
              },
              'account_navigation' =>  {
                'message_type' => 'LtiResourceLinkRequest',
                'canvas_icon_class' => 'icon-lti',
                'icon_url' => 'https://static.thenounproject.com/png/131630-211.png',
                'text' => 'LTI 1.3 Test Tool Course Navigation',
                'enabled' => true
              }
            }
          }
        ]
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
            settings.delete('launch_url')
            settings['extensions'].first.delete('domain')
            settings['extensions'].first.delete('launch_url')
            settings['extensions'].first.dig('settings', 'course_navigation').delete('url')
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
    end

    describe 'before_validation' do
      context 'when "settings_url" is present' do
        subject do
          tool_configuration.validate
          tool_configuration
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
          tool_configuration.settings = nil
          tool_configuration.settings_url = url
          tool_configuration.developer_key = developer_key
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(stubbed_response)
        end

        it 'fetches JSON from the URL' do
          expect(subject.settings).to eq settings
        end

        context 'when a timeout occurs' do
          before { allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Timeout::Error) }

          it 'raises exception if timeout occurs' do
            expect(subject.errors[:settings_url]).to include 'Could not retrieve settings, the server response timed out.'
          end
        end

        context 'when the response is not a success' do
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
            end

            it 'adds a "not found error to the model' do
              expect(subject.errors[:settings_url]).to include 'Not found'
            end
          end

          context 'when the response is "unauthorized"' do
            before do
              allow(stubbed_response).to receive(:message).and_return('Unauthorized')
              allow(stubbed_response).to receive(:code).and_return('401')
            end

            it 'adds a "unauthorized error to the model' do
              expect(subject.errors[:settings_url]).to include 'Unauthorized'
            end
          end

          context 'when the response is "internal server error"' do
            before do
              allow(stubbed_response).to receive(:message).and_return('Internal server error')
              allow(stubbed_response).to receive(:code).and_return('500')
            end

            it 'adds a "internal server error to the model' do
              expect(subject.errors[:settings_url]).to include 'Internal server error'
            end
          end

          context 'when the response is not JSON' do
            before do
              allow(stubbed_response).to receive('[]').and_return('text/html')
              allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return true
            end

            it 'adds an error to the model' do
              expect(subject.errors[:settings_url]).to include 'Content type must be "application/json"'
            end
          end
        end
      end
    end

    describe '#new_external_tool' do
      subject{ tool_configuration.new_external_tool(context) }

      let(:extensions) { settings['extensions'].first }

      before do
        tool_configuration.developer_key = developer_key
        tool_configuration.custom_fields = "key=value\nfoo=bar"
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

        it 'sets the correct placements' do
          expect(subject.settings.keys).to include 'account_navigation'
          expect(subject.settings.keys).to include 'course_navigation'
        end

        it 'uses the correct launch url' do
          expect(subject.url).to eq settings['launch_url']
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
          expect(subject.custom_fields).to eq({"has_expansion"=>"$Canvas.user.id", "no_expansion"=>"foo", "key"=>"value", "foo"=>"bar"})
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

          let(:placement_settings) { extensions.dig('settings', 'course_navigation') }

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

          it 'uses the correct url' do
            expect(subject['url']).to eq placement_settings['url']
          end

          it 'uses the correct value for enabled' do
            expect(subject['enabled']).to eq placement_settings['enabled']
          end

          it 'uses the correct custom fields' do
            expect(subject['custom_fields']).to eq placement_settings['custom_fields']
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

    describe '#create_tool_and_key!' do
      let_once(:account) { Account.create! }
      let(:params) do
        {
          settings: settings
        }
      end

      it 'creates a dev key' do
        expect { described_class.create_tool_and_key! account, params }.to change(DeveloperKey, :count).by(1)
      end

      context 'when tool_config creation fails' do
        let(:settings) { { tool: 'foo' } }

        it 'does not create dev key' do
          expect(DeveloperKey.where(account: account).count).to eq 0
          expect { described_class.create_tool_and_key! account, params }.to raise_error ActiveRecord::RecordInvalid
          expect(DeveloperKey.where(account: account).count).to eq 0
        end
      end
    end
  end
end
