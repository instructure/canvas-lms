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
require_dependency "lti/ims/tool_setting_controller"

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
          product_version: '1',
          workflow_state: 'disabled',
          raw_data: {'proxy' => 'value'},
          lti_version: '1'
        )
      end
      let(:resource_handler) {ResourceHandler.create!(resource_type_code: 'code', name: 'name', tool_proxy: tool_proxy)}
      let(:message_handler) {MessageHandler.create(message_type: 'basic-lti-launch-request', launch_path: 'https://samplelaunch/blti', resource_handler: resource_handler)}
      let(:access_token) {Lti::Oauth2::AccessToken.create_jwt(aud: nil, sub: tool_proxy.guid).to_s}

      before do
        allow_any_instance_of(ToolSettingController).to receive_messages(oauth_authenticated_request?: true)
        allow_any_instance_of(ToolSettingController).to receive_messages(authenticate_body_hash: true)
        allow_any_instance_of(ToolSettingController).to receive_messages(oauth_consumer_key: tool_proxy.guid)
        allow(AuthenticationMethods).to receive_messages(access_token: access_token)
        @link_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, resource_link_id: 'abc', custom: {link: :setting, a: 1, b: 2, c: 3})
        @binding_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, custom: {binding: :setting, a: 1, b: 2, d: 4})
        @proxy_setting = ToolSetting.create(tool_proxy: tool_proxy, custom: {proxy: :setting, a: 1, c: 3, d: 4})
      end

      describe "#show" do

        it 'returns toolsettings.simple when requested' do
          get "/api/lti/tool_settings/#{@link_setting.id}.json",
              params: {tool_setting_id: @link_setting},
              headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => "bearer #{access_token}"}
          expect(response.content_type).to eq 'application/vnd.ims.lti.v2.toolsettings.simple+json'
        end

        it 'returns toolsettings when requested' do
          get "/api/lti/tool_settings/#{@link_setting.id}.json", params: {tool_setting_id: @link_setting},
              headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
          expect(response.content_type).to eq 'application/vnd.ims.lti.v2.toolsettings+json'
        end

        it 'returns not_found if there isn\'t a tool setting' do
          get "/api/lti/tool_settings/3.json", params: {tool_setting_id: '3'},
              headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
          expect(response.code).to eq '404'
          expect(response.body).to eq '{"status":"not_found","errors":[{"message":"not_found"}]}'
        end

        it 'returns as a bad request when bubble is something besides "all" or "distinct"' do
          get "/api/lti/tool_settings/#{@link_setting.id}.json", params: {tool_setting_id: @link_setting, bubble:'pop'},
              headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
          expect(response.code).to eq "400"
        end

        it 'returns as a bad request when bubble is "all" and the accept type is "simple"' do
          get "/api/lti/tool_settings/#{@link_setting.id}.json", params: {tool_setting_id: @link_setting, bubble:'all'},
              headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
          expect(response.code).to eq "400"
        end

        context 'lti_link' do

          it 'returns the lti_link using resource_link_id' do
            get "/api/lti/tool_proxy/#{tool_proxy.guid}/accounts/#{account.id}/resource_link_id/#{@link_setting.resource_link_id}/tool_setting.json",
                params: {
                  tool_proxy_guid: tool_proxy.guid,
                  context_id: account.id,
                  resource_link_id: @link_setting.resource_link_id
                },
                headers: { 'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token' }
            expect(JSON.parse(body)).to eq({ "link" => "setting", "a" => 1, "b" => 2, "c" => 3 })
          end

          it 'returns the lti link simple json' do
            get "/api/lti/tool_settings/#{@link_setting.id}.json", params: {tool_setting_id: @link_setting},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(JSON.parse(body)).to eq({"link" => "setting", "a" => 1, "b" => 2, "c" => 3})
          end

          it 'returns the lti link tool settings json with bubble distinct' do
            get "/api/lti/tool_settings/#{@link_setting.id}.json", params: {tool_setting_id: @link_setting, bubble: 'distinct'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting['custom']).to eq({"link" => "setting", "a" => 1, "b" => 2, "c" => 3})
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting['custom']).to eq({"binding" => "setting", "d" => 4})
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting"})
          end

          it 'returns the lti link tool settings simple json with bubble distinct' do
            get "/api/lti/tool_settings/#{@link_setting.id}.json", params: {tool_setting_id: @link_setting, bubble: 'distinct'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(JSON.parse(body)).to eq({"link" => "setting", "binding" => "setting", "proxy" => "setting", "a" => 1, "b" => 2, "c" => 3, "d" => 4})
          end

          it 'bubbles up all levels' do
            get "/api/lti/tool_settings/#{@link_setting.id}.json", params: {tool_setting_id: @link_setting.id, bubble: 'all'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting['custom']).to eq({"link" => "setting", "a" => 1, "b" => 2, "c" => 3})
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting['custom']).to eq({"binding" => "setting", "a" => 1, "b" => 2, "d" => 4})
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting", "a" => 1, "c" => 3, "d" => 4})
          end

          it 'finds the tool setting by "resource_link_id"' do
            resource_link_id = SecureRandom.uuid
            custom = { test: 'value' }.with_indifferent_access
            tool_setting = Lti::ToolSetting.create!(
              tool_proxy: tool_proxy,
              resource_link_id: resource_link_id,
              custom: custom,
              context: tool_proxy.context
            )
            get "/api/lti/tool_proxy/#{tool_proxy.guid}/accounts/#{tool_proxy.context.id}/resource_link_id/#{resource_link_id}/tool_setting",
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => "bearer #{access_token}"}
            response_body = JSON.parse(response.body)
            expect(response_body).to eq custom
          end
        end

        context 'binding' do
          it 'returns the simple json' do
            get "/api/lti/tool_settings/#{@binding_setting.id}.json", params: {tool_setting_id: @binding_setting.id},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(JSON.parse(body)).to eq({"binding" => "setting", "a" => 1, "b" => 2, "d" => 4})
          end

          it 'returns the lti_link using resource_link_id' do
            get "/api/lti/tool_proxy/#{tool_proxy.guid}/accounts/#{account.id}/tool_setting.json",
                params: {
                  tool_proxy_guid: tool_proxy.guid,
                  context_id: account.id
                },
                headers: { 'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token' }
            expect(JSON.parse(body)).to eq({"binding" => "setting", "a" => 1, "b" => 2, "d" => 4})
          end

          it 'returns the tool settings json with bubble distinct' do
            get "/api/lti/tool_settings/#{@binding_setting.id}.json", params: {tool_setting_id: @link_setting, bubble: 'distinct'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting).to be_nil
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting['custom']).to eq({"binding" => "setting", "a" => 1, "b" => 2, "d" => 4})
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting", "c" => 3})
          end

          it 'returns the tool settings simple json with bubble distinct' do
            get "/api/lti/tool_settings/#{@binding_setting.id}.json", params: {tool_setting_id: @link_setting, bubble: 'distinct'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(JSON.parse(body)).to eq({"binding" => "setting", "proxy" => "setting", "a" => 1, "b" => 2, "c" => 3, "d" => 4})
          end

          it 'bubbles up from binding' do
            get "/api/lti/tool_settings/#{@binding_setting.id}.json", params: {tool_setting_id: @binding_setting.id, bubble: 'all'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting).to be_nil
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting['custom']).to eq({"binding" => "setting", "a" => 1, "b" => 2, "d" => 4})
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting", "a" => 1, "c" => 3, "d" => 4})
          end

        end

        context 'tool proxy' do
          it 'returns the lti link simple json' do
            get "/api/lti/tool_settings/#{@proxy_setting.id}.json", params: {link_id: @proxy_setting.id},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(JSON.parse(body)).to eq({"proxy" => "setting", "a" => 1, "c" => 3, "d" => 4})
          end

          it 'returns the lti_link using resource_link_id' do
            get "/api/lti/tool_proxy/#{tool_proxy.guid}/tool_setting.json",
                params: {
                  tool_proxy_guid: tool_proxy.guid
                },
                headers: { 'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token' }
            expect(JSON.parse(body)).to eq({"proxy" => "setting", "a" => 1, "c" => 3, "d" => 4})
          end

          it 'returns the tool settings json with bubble distinct' do
            get "/api/lti/tool_settings/#{@proxy_setting.id}.json", params: {tool_setting_id: @link_setting, bubble: 'distinct'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting).to be_nil
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting).to be_nil
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting", "a" => 1, "c" => 3, "d" => 4})
          end

          it 'returns the tool settings simple json with bubble distinct' do
            get "/api/lti/tool_settings/#{@proxy_setting.id}.json", params: {tool_setting_id: @link_setting, bubble: 'distinct'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(JSON.parse(body)).to eq({"proxy" => "setting", "a" => 1, "c" => 3, "d" => 4})
          end

          it 'bubbles up from tool proxy' do
            get "/api/lti/tool_settings/#{@proxy_setting.id}.json", params: {tool_setting_id: @proxy_setting.id, bubble: 'all'},
                headers: {'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings+json', 'Authorization' => 'oauth_token'}
            json = JSON.parse(body)
            link_setting = json['@graph'].find { |setting| setting['@type'] == "LtiLink" }
            expect(link_setting).to be_nil
            binding_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxyBinding" }
            expect(binding_setting).to be_nil
            proxy_setting = json['@graph'].find { |setting| setting['@type'] == "ToolProxy" }
            expect(proxy_setting['custom']).to eq({"proxy" => "setting", "a" => 1, "c" => 3, "d" => 4})
          end

        end
      end

      describe "#update" do

        it 'returns as a bad request when bubble is set' do
          tool_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, resource_link_id: 'resource_link')
          params = {'link' => 'settings'}
          put "/api/lti/tool_settings/#{tool_setting.id}.json?bubble=all", params: params.to_json,
              headers: {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings.simple+json',
               'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
          expect(response.code).to eq "400"
        end

        it 'returns as a bad request when there is more than one @graph item' do
          tool_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, resource_link_id: 'resource_link')
          params = {
            "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolSettings",
            '@graph' => [
              {
                '@type' => "LtiLink", "@id" => "http://sample.invalid/api/lti/tool_settings/#{tool_setting.id}",
                "custom" => {'link' => 'settings'}
              },
              {
                '@type' => "ToolProxyBinding", "@id" => "http://sample.invalid/api/lti/tool_settings/#{tool_setting.id + 1}",
                "custom" => {'binding' => 'settings'}
              }
            ]
          }
          put "/api/lti/tool_settings/#{tool_setting.id}.json", params: params.to_json,
              headers: {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings+json',
               'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
          expect(response.code).to eq "400"
        end

        it 'updates a tool_setting with a single graph element' do
          tool_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, resource_link_id: 'resource_link')
          params = params = {
            "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolSettings",
            "@graph" => [
              {
                "@type" => "LtiLink", "@id" => "http://sample.invalid/api/lti/tool_settings/#{tool_setting.id}",
                "custom" => {'link' => 'settings'}
              }
            ]
          }
          put "/api/lti/tool_settings/#{tool_setting.id}.json", params: params.to_json,
              headers: {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings+json',
               'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
          expect(tool_setting.reload.custom).to eq({'link' => 'settings'})
        end

        context "lti_link" do
          it 'creates a new lti link tool setting' do
            tool_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account, resource_link_id: 'resource_link')
            params = {'link' => 'settings'}
            put "/api/lti/tool_settings/#{tool_setting.id}.json", params: params.to_json,
                headers: {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings.simple+json',
                 'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(tool_setting.reload.custom).to eq({'link' => 'settings'})
          end
        end

        context "binding" do
          it 'creates a new binding tool setting' do
            tool_setting = ToolSetting.create(tool_proxy: tool_proxy, context: account)
            params = {'binding' => 'settings'}
            put "/api/lti/tool_settings/#{tool_setting.id}.json", params: params.to_json,
                headers: {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings.simple+json',
                 'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(tool_setting.reload.custom).to eq({'binding' => 'settings'})
          end
        end

        context "proxy" do
          it 'creates a new tool_proxy tool setting' do
            tool_setting = ToolSetting.create(tool_proxy: tool_proxy)
            params = {'tool_proxy' => 'settings'}
            put "/api/lti/tool_settings/#{tool_setting.id}.json", params: params.to_json,
                headers: {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolsettings.simple+json',
                 'HTTP_ACCEPT' => 'application/vnd.ims.lti.v2.toolsettings.simple+json', 'Authorization' => 'oauth_token'}
            expect(tool_setting.reload.custom).to eq({'tool_proxy' => 'settings'})
          end
        end

      end

    end
  end
end
