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
require_relative './concerns/deep_linking_spec_helper'

module Lti
  module Ims
    RSpec.describe DeepLinkingController do
      include_context 'deep_linking_spec_helper'

      describe '#deep_linking_response' do
        subject { post :deep_linking_response, params: params }

        let(:params) { {JWT: deep_linking_jwt, account_id: account.id} }

        it { is_expected.to be_ok }

        it 'sets the JS ENV' do
          expect(controller).to receive(:js_env).with(
            content_items: content_items,
            message: message,
            log: log,
            error_message: error_message,
            error_log: error_log,
            lti_endpoint: Rails.application.routes.url_helpers.polymorphic_url(
              [:retrieve, account, :external_tools],
              host: 'test.host'
            ),
            reload_page: false
          )
          subject
        end

        shared_examples_for 'errors' do
          let(:response_message) { raise 'set in examples' }

          it { is_expected.to be_bad_request }

          it 'responds with an error' do
            subject
            expect(json_parse['errors'].to_s).to include response_message
          end
        end

        context 'when the jti is being reused' do
          let(:jti) { 'static value' }
          let(:nonce_key) { "nonce::#{jti}" }

          before {  Lti::Security.check_and_store_nonce(nonce_key, iat, 30.seconds) }

          it { is_expected.to be_success }
        end

        context 'when the aud is invalid' do
          let(:aud) { 'banana' }

          it_behaves_like 'errors' do
            let(:response_message) { "the 'aud' is invalid" }
          end
        end

        context 'when the jwt format is invalid' do
          let(:deep_linking_jwt) { 'banana' }

          it_behaves_like 'errors' do
            let(:response_message) { 'JWT format is invalid' }
          end
        end

        context 'when the jwt has the wrong alg' do
          let(:alg) { :HS256 }
          let(:private_jwk) { SecureRandom.uuid }

          it_behaves_like 'errors' do
            let(:response_message) { 'JWT has unexpected alg' }
          end
        end

        context 'when jwt verification fails' do
          let(:private_jwk) do
            new_key = DeveloperKey.new
            new_key.generate_rsa_keypair!
            JSON::JWK.new(new_key.private_jwk)
          end

          it_behaves_like 'errors' do
            let(:response_message) { 'JWT verification failure' }
          end
        end

        context 'when a url is used to get public key' do
          let(:rsa_key_pair) { Lti::RSAKeyPair.new }
          let(:url) { "https://get.public.jwk" }
          let(:public_jwk_url_response) do
            {
              keys: [
                public_jwk
              ]
            }
          end
          let(:stubbed_response) { double(success?: true, parsed_response: public_jwk_url_response) }

          def expected_url_called(url, type, response)
            expect(HTTParty).to receive(type).with(url).and_return(response)
          end

          context 'when there is no public jwk' do
            before do
              public_jwk_url_response = { keys: [ public_jwk ] }
              developer_key.update!(public_jwk: nil, public_jwk_url: url)
            end

            it do
              expected_url_called(url, :get, stubbed_response)
              is_expected.to be_success
            end
          end

          context 'when there is a public jwk' do
            before do
              developer_key.update!(public_jwk_url: url)
            end

            it do
              expected_url_called(url, :get, stubbed_response)
              is_expected.to be_success
            end
          end

          context 'when an empty object is returned' do
            let(:public_jwk_url_response) { {} }
            let(:response_message) { 'JWT verification failure' }
            before do
              developer_key.update!(public_jwk_url: url)
            end

            it do
              expected_url_called(url, :get, stubbed_response)
              subject
              expect(json_parse['errors'].to_s).to include response_message
            end
          end

          context 'when the url is not valid giving a 404' do
            let(:stubbed_response) { double(success?: false, parsed_response: public_jwk_url_response.to_json) }
            let(:response_message) { 'JWT verification failure' }

            before do
              developer_key.update!(public_jwk_url: url)
            end

            let(:public_jwk_url_response) do
              {
                success?: false, code: '404'
              }
            end

            it do
              expected_url_called(url, :get, stubbed_response)
              subject
              expect(json_parse['errors'].to_s).to include response_message
            end
          end
        end

        context 'when the developer key is not found' do
          let(:iss) { developer_key.global_id + 100 }

          it_behaves_like 'errors' do
            let(:response_message) { 'Client not found' }
          end
        end

        context 'when the developer key binding is off' do
          before do
            developer_key.developer_key_account_bindings.first.update!(
              workflow_state: 'off'
            )
          end

          it_behaves_like 'errors' do
            let(:response_message) { 'Developer key inactive in context' }
          end
        end

        context 'when the developer key is not active' do
          before do
            developer_key.update!(
              workflow_state: 'deleted'
            )
          end

          it_behaves_like 'errors' do
            let(:response_message) { 'Developer key inactive' }
          end
        end

        context 'when the iat is in the future' do
          let(:iat) { 1.hour.from_now.to_i }

          it_behaves_like 'errors' do
            let(:response_message) { "the 'iat' must not be in the future" }
          end
        end

        context 'when the exp is past' do
          let(:exp) { 1.hour.ago.to_i }

          it_behaves_like 'errors' do
            let(:response_message) { 'the JWT has expired' }
          end
        end

        context 'when multiple content items are received' do
          let(:course) { course_model }
          let(:context_module) { course.context_modules.create!(:name => 'Test Module')}
          let(:developer_key) do
            key = DeveloperKey.create!(account: course.account)
            key.generate_rsa_keypair!
            key.developer_key_account_bindings.first.update!(
              workflow_state: 'on'
            )
            key.save!
            key
          end

          let(:context_external_tool) {
            ContextExternalTool.create!(
              context: course.account,
              url: 'https://www.test.com',
              name: 'test tool',
              shared_secret: 'secret',
              consumer_key: 'key',
              developer_key: developer_key
            )
          }

          let(:params) { super().merge({course_id: course.id, context_module_id: context_module.id})}
          let(:content_items) {
            [
              { type: 'ltiResourceLink', url: 'http://tool.url', title: "Item 1"},
              { type: 'ltiResourceLink', url: 'http://tool.url', title: "Item 2"},
              { type: 'ltiResourceLink', url: 'http://tool.url', title: "Item 3"}
            ]
          }

          it 'creates multiple modules items' do
            course
            user_session(@user)
            context_external_tool
            subject
            is_expected.to be_success
            expect(context_module.content_tags.count).to eq(3)
          end
        end
      end
    end
  end
end
