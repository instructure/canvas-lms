#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')

module Lti
  module Ims
    describe ToolSettingController, type: :request do

      let(:account) { Account.new }
      let (:product_family) { ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account) }
      let(:tool_proxy) do
        ToolProxy.create!(
          context: account,
          guid: SecureRandom.uuid,
          shared_secret: 'abc',
          product_family: product_family,
          root_account: account,
          product_version: '1',
          workflow_state: 'disabled',
          raw_data: {'proxy' => 'value'},
          lti_version: '1'
        )
      end
      let(:resource_handler) { ResourceHandler.create!(resource_type_code: 'code', name: 'name', tool_proxy: tool_proxy) }
      let(:message_handler) { MessageHandler.create(message_type: 'basic-lti-launch-request', launch_path: 'https://samplelaunch/blti', resource_handler: resource_handler) }

      before do
        OAuth::Signature.stubs(:build).returns(mock(verify: true))
        @link_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, resource_link_id: 'abc', custom: {link: :setting})
        @binding_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, custom: {binding: :setting})
        @proxy_setting = ToolSetting.create(tool_proxy: tool_proxy, custom: {proxy: :setting})
      end

      describe '#lti_link_show', type: :request do

        it 'returns the lti link simple json' do
          get "/api/lti/tool_settings/#{@link_setting.id}.json", tool_setting_id: @link_setting, bubble: false
          expect(JSON.parse(body)).to eq({"link" => "setting"})
        end

        it 'returns the lti link tool settings json with bubble' do
          get "/api/lti/tool_settings/#{@link_setting.id}.json", tool_setting_id: @link_setting, bubble: true
          json = JSON.parse(body)
          setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
          expect(setting['custom']).to eq({"link" => "setting"})
        end

        it 'creates a new lti link tool setting' do
          tool_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, resource_link_id: 'resource_link')
          params = {'link' => 'settings'}
          put "/api/lti/tool_settings/#{tool_setting.id}.json", params.to_json, {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json'}
          expect(tool_setting.reload.custom).to eq({'link' => 'settings'})
        end

      end

      describe '#tool_proxy_binding_show' do

        it 'returns the lti link simple json' do
          get "/api/lti/tool_settings/#{@binding_setting.id}.json", tool_setting_id: @binding_setting.id, bubble: false
          expect(JSON.parse(body)).to eq({"binding" => "setting"})
        end

        it 'returns the lti link tool settings json with bubble' do
          get "/api/lti/tool_settings/#{@binding_setting.id}.json", tool_setting_id: @binding_setting.id, bubble: true
          json = JSON.parse(body)
          setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
          expect(setting['custom']).to eq({"binding" => "setting"})
        end

        it 'creates a new binding tool setting' do
          tool_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account)
          params = {'binding' => 'settings'}
          put "/api/lti/tool_settings/#{tool_setting.id}.json", params.to_json, {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json'}
          expect(tool_setting.reload.custom).to eq({'binding' => 'settings'})
        end

      end

      describe '#tool_proxy_show' do

        it 'returns the lti link simple json' do
          get "/api/lti/tool_settings/#{@proxy_setting.id}.json", link_id: @proxy_setting.id, bubble: false
          expect(JSON.parse(body)).to eq({"proxy" => "setting"})
        end

        it 'returns the lti link tool settings json with bubble' do
          get "/api/lti/tool_settings/#{@proxy_setting.id}.json", link_id: @proxy_setting.id, bubble: true
          json = JSON.parse(body)
          setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
          expect(setting['custom']).to eq({"proxy" => "setting"})
        end

        it 'creates a new tool_proxy tool setting' do
          tool_setting = ToolSetting.create(tool_proxy: tool_proxy)
          params = {'tool_proxy' => 'settings'}
          put "/api/lti/tool_settings/#{tool_setting.id}.json", params.to_json, {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json'}
          expect(tool_setting.reload.custom).to eq({'tool_proxy' => 'settings'})
        end

        context 'bubble' do

          it 'bubbles up all levels' do
            get "/api/lti/tool_settings/#{@link_setting.id}.json", tool_setting_id: @link_setting.id, bubble: true
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting['custom']).to eq({"link" => "setting"})
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting['custom']).to eq({"binding" => "setting"})
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting"})
          end

          it 'bubbles up from binding' do
            get "/api/lti/tool_settings/#{@binding_setting.id}.json", tool_setting_id: @binding_setting.id, bubble: true
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting).to be_nil
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting['custom']).to eq({"binding" => "setting"})
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting"})
          end

          it 'bubbles up from tool proxy' do
            get "/api/lti/tool_settings/#{@proxy_setting.id}.json", tool_setting_id: @proxy_setting.id, bubble: true
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting).to be_nil
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting).to be_nil
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting"})
          end

        end

      end

    end
  end
end