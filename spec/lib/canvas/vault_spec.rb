# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../spec_helper"

module Canvas
  describe Vault do
    include WebMock::API

    let(:token) { "canvas_token" }
    let(:token_path) { "/path/to/token" }
    let(:addr) { "http://vault:8200" }
    let(:addr_path) { "/path/to/addr" }
    let(:static_config) do
      {
        token:,
        addr:,
        kv_mount: "app-canvas"
      }
    end
    let(:path_config) do
      {
        token_path:,
        addr_path:,
        kv_mount: "app-canvas"
      }
    end
    let(:local_config) { { token: "file", addr: "file" } }

    before do
      # override default stub in spec_helper.rb since we actually
      # want to test this function in this file
      allow(Canvas::Vault).to receive(:read).and_call_original

      LocalCache.clear(force: true)
      WebMock.disable_net_connect!
    end

    after do
      LocalCache.clear
      WebMock.enable_net_connect!
    end

    describe ".api_client" do
      context "Static config" do
        it "Constructs a client using the address and path from the config" do
          allow(described_class).to receive(:config).and_return(static_config)

          expect(described_class.api_client.address).to eq(addr)
          expect(described_class.api_client.token).to eq(token)
        end
      end

      context "Path config" do
        it "Constructs a client using the address and path from the config" do
          allow(described_class).to receive(:config).and_return(path_config)

          allow(File).to receive(:read).with(token_path).and_return(token + "_frompath")
          allow(File).to receive(:read).with(addr_path).and_return(addr + "_frompath")
          expect(described_class.api_client.address).to eq(addr + "_frompath")
          expect(described_class.api_client.token).to eq(token + "_frompath")
        end
      end
    end

    describe ".read" do
      before do
        allow(described_class).to receive(:config).and_return(static_config)
        @stub = stub_request(:get, "#{addr}/v1/test/path")
                .to_return(status: 200,
                           body: {
                             data: {
                               foo: "bar"
                             },
                             lease_duration: 3600,
                           }.to_json,
                           headers: { "content-type": "application/json" })
        stub_request(:get, "#{addr}/v1/bad/test/path")
          .to_return(status: 404, headers: { "content-type": "application/json" })
      end

      it "Caches the read" do
        expect(described_class.read("test/path")).to eq({ foo: "bar" })
        expect(@stub).to have_been_requested.times(1)
        # uses the cache
        expect(described_class.read("test/path")).to eq({ foo: "bar" })
        expect(@stub).to have_been_requested.times(1)
      end

      it "Does not cache the read if not desired" do
        expect(described_class.read("test/path", cache: false)).to eq({ foo: "bar" })
        expect(@stub).to have_been_requested.times(1)
        # still does not use the cache
        expect(described_class.read("test/path", cache: false)).to eq({ foo: "bar" })
        expect(@stub).to have_been_requested.times(2)
      end

      it "Caches the read for less than the lease_duration" do
        expect(described_class.read("test/path")).to eq({ foo: "bar" })
        expect(@stub).to have_been_requested.times(1)
        # does not use the cache
        Timecop.travel(3600.seconds.from_now) do
          expect(described_class.read("test/path")).to eq({ foo: "bar" })
          expect(@stub).to have_been_requested.times(2)
        end
      end

      it "Uses the cache if vault is unavailible" do
        expect(described_class.read("test/path")).to eq({ foo: "bar" })
        expect(@stub).to have_been_requested.times(1)
        # restub to return an error now
        stub_request(:get, "#{addr}/v1/test/path").to_return(status: 500, body: "error")
        Timecop.travel(3600.seconds.from_now) do
          expect(described_class.read("test/path")).to eq({ foo: "bar" })
        end
      end

      it "reads from disk config if configured to do so" do
        # make sure we bust the FileClient cache because if it's already been
        # used, it won't try to re-load the `vault_contents` config file
        Canvas::Vault::FileClient.reset!
        cred_path = "sts/testaccount/sts/canvas-shards-lookupper-test"
        creds_hash = {
          cred_path => {
            "access_key" => "fake-access-key",
            "secret_key" => "fake-secret-key",
            "security_token" => "fake-security-token"
          }
        }
        allow(described_class).to receive(:config).and_return(local_config)
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("vault_contents").and_return(creds_hash)
        result = described_class.read(cred_path)
        expect(result[:security_token]).to eq("fake-security-token")
      end

      it "Throws an error if not found by default" do
        expect { described_class.read("bad/test/path") }.to raise_error(Vault::MissingVaultSecret)
      end

      it "Returns nil if not found and not required" do
        expect(described_class.read("bad/test/path", required: false)).to be_nil
      end

      describe "locking and loading" do
        let(:credential_path) { "test/vault/creds/path" }
        let(:lease_duration) { 3600 }
        let(:credential_data) { { credential_id: "aabbccdd", credential_secret: "pampelmousse" } }

        before do
          skip("Must have a local redis available to run this spec") unless Canvas.redis_enabled?
          allow(ConfigFile).to receive(:load).with("local_cache").and_return({
                                                                               store: "redis",
                                                                               redis_host: "redis",
                                                                               redis_port: 6379,
                                                                               redis_db: 6 # intentionally one probably not used elsewhere
                                                                             })
          allow(ConfigFile).to receive(:load).and_call_original
          @lock_stub = stub_request(:get, "#{addr}/v1/#{credential_path}")
                       .to_return(status: 200,
                                  body: {
                                    data: credential_data,
                                    lease_duration:,
                                  }.to_json,
                                  headers: { "content-type": "application/json" })
        end

        it "will queue if the lock is taken and there is no value in the cache" do
          expect(LocalCache.fetch(::Canvas::Vault::CACHE_KEY_PREFIX + credential_path)).to be_nil
          t1_val = t2_val = t3_val = t4_val = nil
          threads = [
            Thread.new { t1_val = described_class.read(credential_path) },
            Thread.new { t2_val = described_class.read(credential_path) },
            Thread.new { t3_val = described_class.read(credential_path) },
            Thread.new { t4_val = described_class.read(credential_path) }
          ]
          threads.each(&:join)
          expect(t1_val).to eq(credential_data)
          expect(t2_val).to eq(credential_data)
          expect(t3_val).to eq(credential_data)
          expect(t4_val).to eq(credential_data)
          expect(@lock_stub).to have_been_requested.times(1)
        end

        it "respects the lease duration for expiration" do
          cache_key = ::Canvas::Vault::CACHE_KEY_PREFIX + credential_path
          expect(LocalCache.fetch(cache_key)).to be_nil
          described_class.read(credential_path)
          cache_entry = LocalCache.cache.send(:read_entry, LocalCache.cache.send(:normalize_key, cache_key, {}))
          expiry_approximate = Time.now.utc.to_i + (lease_duration / 2)
          expiry_delta = (cache_entry.expires_at - expiry_approximate).abs
          expect(expiry_delta.abs < 30).to be_truthy
        end
      end
    end
  end
end
