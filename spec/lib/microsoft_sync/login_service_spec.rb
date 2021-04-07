# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative '../../spec_helper'

describe MicrosoftSync::LoginService do
  include WebMock::API

  describe '.new_token' do
    around { |example| Setting.skip_cache(&example) }

    before { WebMock.disable_net_connect! }

    after { WebMock.enable_net_connect! }

    context 'when not configured' do
      before do
        allow(Rails.application.credentials).to receive(:microsoft_sync).and_return(nil)
      end

      it 'returns an error "MicrosoftSync not configured"' do
        expect {
          described_class.new_token('abc')
        }.to raise_error(/Missing MicrosoftSync creds/)
      end
    end

    context 'when configured' do
      subject { described_class.new_token('mytenant') }

      before do
        allow(Rails.application.credentials).to receive(:microsoft_sync).and_return({
          client_id: 'theclientid',
          client_secret: 'thesecret'
        })

        WebMock.stub_request(
          :post, 'https://login.microsoftonline.com/mytenant/oauth2/v2.0/token'
        ).with(
          body: {
            scope: 'https://graph.microsoft.com/.default',
            grant_type: 'client_credentials',
            client_id: 'theclientid',
            client_secret: 'thesecret'
          }
        ).and_return(
          status: response_status,
          body: response_body.to_json,
          headers: {'Content-type' => 'application/json'},
        )
      end

      context 'when Microsoft returns a 200' do
        let(:response_status) { 200 }
        let(:response_body) do
          { 'token_type' => 'Bearer', 'expires_in' => 3599, 'access_token' => 'themagicaltoken' }
        end

        it { is_expected.to eq(response_body) }
      end

      context 'when Microsoft returns a non-200 response' do
        let(:response_status) { 401 }
        let(:response_body) { {} }

        it 'raises an HTTPInvalidStatus' do
          expect { subject }.to raise_error(
            MicrosoftSync::Errors::HTTPInvalidStatus,
            /Login service returned 401 for tenant mytenant/
          )
        end
      end
    end
  end

  describe '.token' do
    shared_examples_for 'a cache that uses the specified expiry' do
      it 'caches the token until the expiry specified by Microsoft, minus a buffer time' do
        enable_cache do
          expect(described_class).to receive(:new_token).once.with('some_tenant').and_return({
            'expires_in' => specified_expiry, 'access_token' => 'firsttoken'
          })

          expect(described_class.token('some_tenant')).to eq('firsttoken')
          Timecop.freeze((specified_expiry - 16).seconds.from_now) do
            expect(described_class.token('some_tenant')).to eq('firsttoken')
          end

          expect(described_class).to receive(:new_token).once.with('some_tenant').and_return({
            'expires_in' => specified_expiry, 'access_token' => 'secondtoken'
          })

          Timecop.freeze((specified_expiry - 1).seconds.from_now) do
            expect(described_class.token('some_tenant')).to eq('secondtoken')
          end
        end
      end
    end

    context 'when Microsoft uses the default expiry' do
      let(:specified_expiry) { described_class::CACHE_DEFAULT_EXPIRY.to_i }

      it_behaves_like 'a cache that uses the specified expiry'
    end

    context 'when Microsoft uses a different expiry' do
      let(:specified_expiry) { 123 }

      it_behaves_like 'a cache that uses the specified expiry'
    end

    it 'caches per tenant' do
      enable_cache do
        expect(described_class).to receive(:new_token).once.with('some_tenant').and_return({
          'expires_in' => 123, 'access_token' => 'firsttoken'
        })
        expect(described_class).to receive(:new_token).once.with('another_tenant').and_return({
          'expires_in' => 123, 'access_token' => 'secondtoken'
        })
        expect(described_class.token('some_tenant')).to eq('firsttoken')
        expect(described_class.token('some_tenant')).to eq('firsttoken')
        expect(described_class.token('another_tenant')).to eq('secondtoken')
        expect(described_class.token('some_tenant')).to eq('firsttoken')
      end
    end
  end
end
