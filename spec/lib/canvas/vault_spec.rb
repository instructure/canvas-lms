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

    describe ".addr" do
      after do
        ENV.delete("VAULT_ADDR")
      end

      it "uses config file addr over VAULT_ADDR environment variable" do
        ENV["VAULT_ADDR"] = "http://vault-from-env:8200"
        allow(described_class).to receive(:config).and_return(static_config)

        # config addr takes precedence over env var
        expect(described_class.api_client.address).to eq(addr)
        expect(static_config[:addr]).to eq(addr) # confirm config had a value
      end

      it "uses addr_path file over VAULT_ADDR" do
        ENV["VAULT_ADDR"] = "http://vault-from-env:8200"
        allow(described_class).to receive(:config).and_return(path_config)
        allow(File).to receive(:read).with(token_path).and_return(token)
        allow(File).to receive(:read).with(addr_path).and_return("http://vault-from-file:8200")

        expect(described_class.api_client.address).to eq("http://vault-from-file:8200")
      end

      it "falls back to VAULT_ADDR when config addr is not set" do
        ENV["VAULT_ADDR"] = "http://vault-from-env:8200"
        config_without_addr = { token:, kv_mount: "app-canvas" }
        allow(described_class).to receive(:config).and_return(config_without_addr)

        expect(described_class.api_client.address).to eq("http://vault-from-env:8200")
      end

      it "falls back to addr_path file when VAULT_ADDR is not set" do
        ENV.delete("VAULT_ADDR")
        allow(described_class).to receive(:config).and_return(path_config)
        allow(File).to receive(:read).with(token_path).and_return(token)
        allow(File).to receive(:read).with(addr_path).and_return("http://vault-from-file:8200")

        expect(described_class.api_client.address).to eq("http://vault-from-file:8200")
      end

      it "ignores empty VAULT_ADDR" do
        ENV["VAULT_ADDR"] = ""
        allow(described_class).to receive(:config).and_return(static_config)

        expect(described_class.api_client.address).to eq(addr)
      end
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

      context "IAM auth config" do
        let(:iam_token) { "s.iam_generated_token" }
        let(:lease_duration) { 3600 }

        before do
          allow(described_class).to receive(:config).and_return(static_config)
          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV["VAULT_AWS_AUTH_ROLE"] = "canvas-role"
        end

        after do
          ENV.delete("VAULT_IAM_AUTH_ENABLED")
          ENV.delete("VAULT_AWS_AUTH_ROLE")
        end

        it "uses IAM token when IAM auth is enabled" do
          mock_secret = double(
            "Vault::Secret",
            auth: double(
              "auth",
              client_token: iam_token,
              lease_duration:
            )
          )

          # First call to Vault::Client.new is during authentication (no token)
          mock_auth_client = instance_double(::Vault::Client)
          mock_auth = double("auth")
          allow(::Vault::Client).to receive(:new).with(address: addr).and_return(mock_auth_client)
          allow(mock_auth_client).to receive(:auth).and_return(mock_auth)
          allow(mock_auth).to receive(:aws_iam).with(role: "canvas-role", mount: "aws").and_return(mock_secret)

          # Second call to Vault::Client.new is for the final client (with token)
          mock_final_client = instance_double(::Vault::Client, token: iam_token)
          allow(::Vault::Client).to receive(:new).with(address: addr, token: iam_token).and_return(mock_final_client)

          expect(described_class.api_client.token).to eq(iam_token)
        end
      end
    end

    describe "IAM authentication" do
      let(:iam_token) { "s.iam_generated_token" }
      let(:lease_duration) { 3600 }

      before do
        allow(described_class).to receive(:config).and_return(static_config)
      end

      after do
        ENV.delete("VAULT_IAM_AUTH_ENABLED")
        ENV.delete("VAULT_AWS_AUTH_ROLE")
        ENV.delete("VAULT_AWS_AUTH_PATH")
        ENV.delete("VAULT_AWS_AUTH_HEADER_VALUE")
        # Clear the in-memory token cache
        described_class.instance_variable_set(:@iam_token_cache, nil)
      end

      describe ".iam_auth_enabled?" do
        it "returns true when VAULT_IAM_AUTH_ENABLED is true" do
          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          expect(described_class.send(:iam_auth_enabled?)).to be true
        end

        it "returns true when VAULT_IAM_AUTH_ENABLED is 1" do
          ENV["VAULT_IAM_AUTH_ENABLED"] = "1"
          expect(described_class.send(:iam_auth_enabled?)).to be true
        end

        it "returns false when VAULT_IAM_AUTH_ENABLED is false" do
          ENV["VAULT_IAM_AUTH_ENABLED"] = "false"
          expect(described_class.send(:iam_auth_enabled?)).to be false
        end

        it "returns false when VAULT_IAM_AUTH_ENABLED is not set" do
          ENV.delete("VAULT_IAM_AUTH_ENABLED")
          expect(described_class.send(:iam_auth_enabled?)).to be_falsey
        end
      end

      describe ".authenticate_with_iam" do
        it "raises VaultAuthError when VAULT_AWS_AUTH_ROLE is not set" do
          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV.delete("VAULT_AWS_AUTH_ROLE")
          expect { described_class.send(:authenticate_with_iam) }
            .to raise_error(Canvas::Vault::VaultAuthError, /VAULT_AWS_AUTH_ROLE required/)
        end

        it "authenticates successfully and caches the token in memory" do
          mock_secret = double(
            "Vault::Secret",
            auth: double(
              "auth",
              client_token: iam_token,
              lease_duration:
            )
          )

          mock_client = instance_double(::Vault::Client)
          mock_auth = double("auth")
          allow(::Vault::Client).to receive(:new).with(address: addr).and_return(mock_client)
          allow(mock_client).to receive(:auth).and_return(mock_auth)
          allow(mock_auth).to receive(:aws_iam).with(role: "canvas-role", mount: "aws").and_return(mock_secret)

          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV["VAULT_AWS_AUTH_ROLE"] = "canvas-role"
          result = described_class.send(:authenticate_with_iam)
          expect(result).to eq(iam_token)

          cached = described_class.instance_variable_get(:@iam_token_cache)
          expect(cached[:token]).to eq(iam_token)
          expect(cached[:lease_duration]).to eq(lease_duration)
        end

        it "uses custom auth path when VAULT_AWS_AUTH_PATH is set" do
          mock_secret = double(
            "Vault::Secret",
            auth: double(
              "auth",
              client_token: iam_token,
              lease_duration:
            )
          )

          mock_client = instance_double(::Vault::Client)
          mock_auth = double("auth")
          allow(::Vault::Client).to receive(:new).with(address: addr).and_return(mock_client)
          allow(mock_client).to receive(:auth).and_return(mock_auth)
          allow(mock_auth).to receive(:aws_iam)
            .with(role: "canvas-role", mount: "custom-aws-path")
            .and_return(mock_secret)

          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV["VAULT_AWS_AUTH_ROLE"] = "canvas-role"
          ENV["VAULT_AWS_AUTH_PATH"] = "custom-aws-path"
          result = described_class.send(:authenticate_with_iam)
          expect(result).to eq(iam_token)
        end

        it "includes server ID header when VAULT_AWS_AUTH_HEADER_VALUE is set" do
          mock_secret = double(
            "Vault::Secret",
            auth: double(
              "auth",
              client_token: iam_token,
              lease_duration:
            )
          )

          mock_client = instance_double(::Vault::Client)
          mock_auth = double("auth")
          allow(::Vault::Client).to receive(:new).with(address: addr).and_return(mock_client)
          allow(mock_client).to receive(:auth).and_return(mock_auth)
          allow(mock_auth).to receive(:aws_iam)
            .with(role: "canvas-role", mount: "aws", iam_server_id_header_value: "vault.example.com")
            .and_return(mock_secret)

          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV["VAULT_AWS_AUTH_ROLE"] = "canvas-role"
          ENV["VAULT_AWS_AUTH_HEADER_VALUE"] = "vault.example.com"
          result = described_class.send(:authenticate_with_iam)
          expect(result).to eq(iam_token)
        end

        it "falls back to expired cached token on auth failure" do
          cached_data = {
            token: "cached_expired_token",
            lease_duration: 3600,
            obtained_at: Time.now.to_i - 7200 # expired 2 hours ago
          }
          described_class.instance_variable_set(:@iam_token_cache, cached_data)

          mock_client = instance_double(::Vault::Client)
          mock_auth = double("auth")
          allow(::Vault::Client).to receive(:new).with(address: addr).and_return(mock_client)
          allow(mock_client).to receive(:auth).and_return(mock_auth)
          allow(mock_auth).to receive(:aws_iam).and_raise(::Vault::HTTPError.new(addr, double(code: "403")))

          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV["VAULT_AWS_AUTH_ROLE"] = "canvas-role"
          result = described_class.send(:authenticate_with_iam)
          expect(result).to eq("cached_expired_token")
        end

        it "raises VaultAuthError when auth fails and no cached token exists" do
          described_class.instance_variable_set(:@iam_token_cache, nil)

          mock_client = instance_double(::Vault::Client)
          mock_auth = double("auth")
          allow(::Vault::Client).to receive(:new).with(address: addr).and_return(mock_client)
          allow(mock_client).to receive(:auth).and_return(mock_auth)
          allow(mock_auth).to receive(:aws_iam).and_raise(::Vault::HTTPError.new(addr, double(code: "403")))

          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV["VAULT_AWS_AUTH_ROLE"] = "canvas-role"
          expect { described_class.send(:authenticate_with_iam) }
            .to raise_error(Canvas::Vault::VaultAuthError, /Failed to authenticate to Vault with IAM/)
        end
      end

      describe ".iam_token" do
        it "returns cached token if valid" do
          cached_data = {
            token: "cached_valid_token",
            lease_duration: 3600,
            obtained_at: Time.now.to_i
          }
          described_class.instance_variable_set(:@iam_token_cache, cached_data)

          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV["VAULT_AWS_AUTH_ROLE"] = "canvas-role"
          expect(described_class.send(:iam_token)).to eq("cached_valid_token")
        end

        it "re-authenticates when cached token is about to expire" do
          # Token obtained 3400 seconds ago (within 300s buffer of expiry)
          cached_data = {
            token: "cached_expiring_token",
            lease_duration: 3600,
            obtained_at: Time.now.to_i - 3400
          }
          described_class.instance_variable_set(:@iam_token_cache, cached_data)

          mock_secret = double(
            "Vault::Secret",
            auth: double(
              "auth",
              client_token: "new_iam_token",
              lease_duration: 3600
            )
          )

          mock_client = instance_double(::Vault::Client)
          mock_auth = double("auth")
          allow(::Vault::Client).to receive(:new).with(address: addr).and_return(mock_client)
          allow(mock_client).to receive(:auth).and_return(mock_auth)
          allow(mock_auth).to receive(:aws_iam).with(role: "canvas-role", mount: "aws").and_return(mock_secret)

          ENV["VAULT_IAM_AUTH_ENABLED"] = "true"
          ENV["VAULT_AWS_AUTH_ROLE"] = "canvas-role"
          expect(described_class.send(:iam_token)).to eq("new_iam_token")
        end
      end

      describe ".iam_token_valid?" do
        it "returns true when token has time remaining beyond buffer" do
          cached = {
            token: "test_token",
            lease_duration: 3600,
            obtained_at: Time.now.to_i
          }
          expect(described_class.send(:iam_token_valid?, cached)).to be true
        end

        it "returns false when token is within refresh buffer" do
          cached = {
            token: "test_token",
            lease_duration: 3600,
            obtained_at: Time.now.to_i - 3400 # 200s remaining, less than 300s buffer
          }
          expect(described_class.send(:iam_token_valid?, cached)).to be false
        end

        it "returns false when token is expired" do
          cached = {
            token: "test_token",
            lease_duration: 3600,
            obtained_at: Time.now.to_i - 7200 # expired 1 hour ago
          }
          expect(described_class.send(:iam_token_valid?, cached)).to be false
        end
      end
    end

    describe ".read / .cached?" do
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

      it "checks if the read is cached" do
        expect(described_class.cached?("test/path")).to be_falsey
        described_class.read("test/path")
        expect(described_class.cached?("test/path")).to be_truthy
        Timecop.travel(3600.seconds.from_now) do
          expect(described_class.cached?("test/path")).to be_truthy
        end
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
