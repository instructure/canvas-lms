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
            )
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
      end
    end
  end
end
