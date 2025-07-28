# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_relative "deep_linking_spec_helper"

describe Lti::IMS::Concerns::DeepLinkingServices do
  describe "DeepLinkingJwt" do
    include_context "deep_linking_spec_helper"
    specs_require_cache(:redis_cache_store)
    include WebMock::API

    let(:public_jwk_url) { "http://example.instructure.com/jwks" }
    let(:jwks) { { "keys" => [public_jwk] } }
    let(:jwks_json) { jwks.to_json }

    before do
      developer_key.update!(public_jwk_url:)
      allow(CanvasHttp).to receive(:get).with(public_jwk_url).and_call_original
    end

    # NOTE: JWKs only fetched and JWTs validated when we call valid? or invalid?
    def make_jwt
      described_class::DeepLinkingJwt.new(deep_linking_jwt, developer_key.account)
    end

    def stub_jwks_request(json = nil)
      stub_request(:get, public_jwk_url).to_return(status: 200, body: json || jwks_json)
    end

    it "caches the JWKs" do
      stub_jwks_request
      expect(make_jwt).to be_valid
      expect(CanvasHttp).to have_received(:get).exactly(:once)

      stub_request(:get, public_jwk_url).to_return(status: 500, body: "{}")
      expect(make_jwt).to be_valid
      expect(CanvasHttp).to have_received(:get).exactly(:once)
    end

    it "caches the JWKs for 5 minutes" do
      allow(Rails.cache).to receive(:write).and_call_original
      stub_jwks_request
      expect(make_jwt).to be_valid
      expect(Rails.cache).to have_received(:write).with(
        a_string_matching(/^dev_key_public_jwk_url/),
        jwks,
        expires_in: 5.minutes
      )
    end

    it "caches by URL unders unique but safe (no special chars) cache key" do
      # Stub default value
      allow(Rails.cache).to receive(:read).and_call_original

      urls = [
        "http://instructure.com/a/b",
        "http://instructure.com/a.b",
        "http://instructure.com/a?b",
        "http://instructure.com/a#b",
      ]

      cache_keys = []

      urls.each do |url|
        allow(Rails.cache).to \
          receive(:read).with(a_string_matching(/^dev_key_public_jwk_url/)) do |cache_key|
            expect(cache_key).to match(%r{\Adev_key_public_jwk_url/[^/.?#]+\z})
            cache_keys << cache_key
            jwks
          end

        developer_key.update! public_jwk_url: url
        expect(make_jwt).to be_valid
      end

      expect(cache_keys.length).to eq(urls.length)
      expect(cache_keys.uniq.length).to eq(urls.length)
      expect(CanvasHttp).not_to have_received(:get)
    end

    context "when decoding from cached jwk fails" do
      let(:cache_key) do
        [
          "dev_key_public_jwk_url",
          Digest::SHA256.hexdigest(developer_key.public_jwk_url),
        ].cache_key
      end

      before do
        Rails.cache.write(cache_key, { "foo" => "bar" })
      end

      it "refetches and saves to cache if decoding with new jwks succeeds" do
        stub_jwks_request

        expect(make_jwt).to be_valid
        expect(Rails.cache.read(cache_key)).to eq(jwks)
      end

      it "causes an invalid JWT on network errors" do
        expect(CanvasHttp).to receive(:get).and_raise SocketError
        expect(make_jwt).not_to be_valid
        expect(Rails.cache.read(cache_key)).to eq({ "foo" => "bar" })
      end

      it "causes an invalid JWT if the endpoint returns bad JSON" do
        stub_jwks_request("not json")
        expect(make_jwt).not_to be_valid
        expect(Rails.cache.read(cache_key)).to eq({ "foo" => "bar" })
      end

      it "refetches and doesn't save to cache if decoding with new jwks fails" do
        wrong_public_jwk =  CanvasSecurity::RSAKeyPair.new.public_jwk.to_h
        wrong_jwks_json = { "keys" => [wrong_public_jwk] }.to_json
        stub_jwks_request(wrong_jwks_json.to_json)
        expect(make_jwt).not_to be_valid
        expect(Rails.cache.read(cache_key)).to eq({ "foo" => "bar" })
      end
    end

    context "when the lti_cache_tool_public_jwk_url feature flag is disabled" do
      it "fetches the JWKs every time" do
        developer_key.root_account.disable_feature!(:lti_cache_tool_public_jwks_url)

        2.times do |n|
          stub_jwks_request
          expect(make_jwt).to be_valid
          expect(CanvasHttp).to have_received(:get).exactly(n + 1).times
        end
      end
    end
  end
end
