# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe OAuthClientConfig do
  before do
    OAuthClientConfig::Cache.clear_memory_cache
  end

  describe "validations" do
    let(:account) { account_model }
    let(:user) { user_model }
    let(:other_account) { account_model }
    let(:config) { OAuthClientConfig.new(root_account: account, type: :token, identifier: "abc123", updated_by: user) }

    it "requires a root_account" do
      config.root_account = nil
      expect(config).not_to be_valid
      expect(config.errors[:root_account]).to include("must exist")
    end

    it "requires a client_identifier" do
      config.identifier = nil
      expect(config).not_to be_valid
      expect(config.errors[:identifier]).to include("can't be blank")
    end

    it "requires a type" do
      config.type = nil
      expect(config).not_to be_valid
      expect(config.errors[:type]).to include("can't be blank")
    end

    it "requires a valid type" do
      config.type = "invalid"
      expect(config).not_to be_valid
      expect(config.errors[:type]).to include("is not included in the list")
    end

    it "requires updated_by" do
      config.updated_by = nil
      expect(config).not_to be_valid
      expect(config.errors[:updated_by]).to include("must exist")
    end

    it "enforces uniqueness of identifier scoped to root_account and type" do
      config.save!
      dup = OAuthClientConfig.new(root_account: account, type: :token, identifier: "abc123", updated_by: user)
      expect(dup).not_to be_valid
      expect(dup.errors[:identifier]).to include("has already been taken")

      # different account is ok
      dup.root_account = other_account
      expect(dup).to be_valid

      # different type is ok
      dup.type = :user
      expect(dup).to be_valid
    end

    it "only allows custom throttle params for certain client types" do
      config.type = "user"
      config.throttle_maximum = 10
      expect(config).not_to be_valid
      expect(config.errors[:type]).to include("custom throttle parameters can only be set for client types: custom, product, client_id, lti_advantage, service_user_key, token")

      config.type = "client_id"
      expect(config).to be_valid
    end
  end

  describe ".find_by_cached" do
    let(:root_account) { account_model }
    let(:user) { user_model }
    let(:client_identifiers) { ["product:1234"] }

    it "returns nil when no config exists" do
      expect(OAuthClientConfig.find_by_cached(root_account, ["nonexistent"])).to be_nil
    end

    it "ignores invalid client identifiers" do
      expect(OAuthClientConfig.find_by_cached(root_account, ["token:1234"])).to be_nil
      expect(OAuthClientConfig.find_by_cached(root_account, ["also:invalid:too_many_parts"])).to be_nil
      expect(OAuthClientConfig.find_by_cached(root_account, ["no_colon"])).to be_nil
    end

    context "with cross-shard configs" do
      specs_require_sharding

      let(:local_user) { @shard2.activate { user_model } }
      let!(:local_config) { @shard2.activate { OAuthClientConfig.create!(root_account:, type: :product, identifier: "1234", throttle_high_water_mark: 10, updated_by: local_user) } }
      let!(:site_admin_config) { OAuthClientConfig.create!(root_account: Account.site_admin, type: :product, identifier: "1234", throttle_high_water_mark: 5, updated_by: user) }

      it "prefers the site admin config" do
        @shard2.activate do
          config = OAuthClientConfig.find_by_cached(root_account, client_identifiers)
          expect(config).to eq(site_admin_config)
        end
      end

      it "returns the local config if no site admin config exists" do
        @shard2.activate do
          site_admin_config.destroy
          config = OAuthClientConfig.find_by_cached(root_account, client_identifiers)
          expect(config).to eq(local_config)
        end
      end
    end

    context "with multiple identifiers" do
      let(:client_identifiers) { ["token:abcd", "product:1234", "service_user_key:xyz"] }
      let!(:low_priority_config) { OAuthClientConfig.create!(root_account:, type: :service_user_key, identifier: "xyz", throttle_high_water_mark: 100, updated_by: user) }
      let!(:high_priority_config) { OAuthClientConfig.create!(root_account:, type: :product, identifier: "1234", throttle_high_water_mark: 500, updated_by: user) }

      it "returns the highest-priority config" do
        config = OAuthClientConfig.find_by_cached(root_account, client_identifiers)
        expect(config).to eq(high_priority_config)
      end

      it "returns the next-highest-priority config if the top one is missing" do
        high_priority_config.destroy
        config = OAuthClientConfig.find_by_cached(root_account, client_identifiers)
        expect(config).to eq(low_priority_config)
      end

      it "only returns configs that are allowed to have custom throttle params" do
        low_priority_config.destroy
        high_priority_config.destroy
        expect(OAuthClientConfig.find_by_cached(root_account, client_identifiers)).to be_nil
      end
    end
  end

  describe ".find_all_cached" do
    specs_require_cache(:redis_cache_store)

    subject { OAuthClientConfig.find_all_cached(root_account, client_identifiers) }

    let(:root_account) { account_model }
    let(:user) { user_model }
    let(:client_identifiers) { ["custom:test", "token:abcd", "product:1234", "service_user_key:xyz"] }
    let(:custom_config) { OAuthClientConfig.create!(root_account:, type: :custom, identifier: "test", throttle_high_water_mark: 1, updated_by: user) }
    let(:token_config) { OAuthClientConfig.create!(root_account:, type: :token, identifier: "abcd", throttle_high_water_mark: 2, updated_by: user) }

    it "returns an empty array when no configs exist" do
      expect(subject).to eq([])
    end

    context "with some matching configs" do
      before do
        custom_config
        token_config
      end

      it "returns the matching configs" do
        expect(subject).to match_array([custom_config, token_config])
      end

      it "caches the results in memory" do
        expect(OAuthClientConfig::Cache.memory_cache).to be_empty
        subject
        expect(OAuthClientConfig::Cache.memory_cache).to include("custom:test" => custom_config, "token:abcd" => token_config)
      end

      it "caches the results in Redis" do
        redis_cache = OAuthClientConfig::Cache.standard_cache
        subject
        expect(redis_cache.read(OAuthClientConfig::Cache.cache_key("custom:test"))).to eq(custom_config)
        expect(redis_cache.read(OAuthClientConfig::Cache.cache_key("token:abcd"))).to eq(token_config)
      end

      context "when called again" do
        it "pulls all results from memory cache" do
          subject
          allow(OAuthClientConfig::Cache).to receive(:read_all_from_cache).and_call_original
          OAuthClientConfig.find_all_cached(root_account, client_identifiers)
          expect(OAuthClientConfig::Cache).not_to have_received(:read_all_from_cache)
        end

        it "only hits DB for uncached configs" do
          subject
          new_identifiers = client_identifiers + ["product:4567"]
          allow(OAuthClientConfig::Cache).to receive(:read_all_from_cache).and_call_original
          allow(OAuthClientConfig).to receive(:find_for_identifiers).and_call_original

          OAuthClientConfig.find_all_cached(root_account, new_identifiers)
          expect(OAuthClientConfig::Cache).to have_received(:read_all_from_cache).twice
          expect(OAuthClientConfig).to have_received(:find_for_identifiers).with(root_account, ["product:4567"])
        end
      end
    end

    context "with all matching configs" do
      let(:product_config) { OAuthClientConfig.create!(root_account:, type: :product, identifier: "1234", throttle_high_water_mark: 3, updated_by: user) }
      let(:service_user_key_config) { OAuthClientConfig.create!(root_account:, type: :service_user_key, identifier: "xyz", throttle_high_water_mark: 4, updated_by: user) }

      before do
        custom_config
        token_config
        product_config
        service_user_key_config
      end

      it "returns all the matching configs" do
        expect(subject).to match_array([custom_config, token_config, product_config, service_user_key_config])
      end

      context "when called again" do
        it "does not hit the DB" do
          subject
          allow(OAuthClientConfig).to receive(:find_for_identifiers).and_call_original

          # uses memory cache
          OAuthClientConfig.find_all_cached(root_account, client_identifiers)
          expect(OAuthClientConfig).not_to have_received(:find_for_identifiers)

          # uses Redis cache
          OAuthClientConfig::Cache.clear_memory_cache
          OAuthClientConfig.find_all_cached(root_account, client_identifiers)
          expect(OAuthClientConfig).not_to have_received(:find_for_identifiers)
        end
      end
    end
  end

  describe "caching" do
    let(:account) { account_model }
    let(:user) { user_model }
    let(:config) { OAuthClientConfig.create!(root_account: account, type: :token, identifier: "abc123", updated_by: user, throttle_high_water_mark: 10) }
    let(:client_identifier) { "token:abc123" }

    before do
      allow(OAuthClientConfig::Cache).to receive(:delete).and_call_original
      config
    end

    it "clears cache after update" do
      expect(OAuthClientConfig.find_cached(account, client_identifier)).to eq(config)

      config.update!(throttle_high_water_mark: 20)
      expect(OAuthClientConfig::Cache).to have_received(:delete).with(client_identifier)

      new_cached = OAuthClientConfig.find_cached(account, client_identifier)
      expect(new_cached).to eq(config)
      expect(new_cached.throttle_high_water_mark).to eq(20)
    end
  end

  describe "Cache" do
    describe ".cache_for" do
      it "uses MultiCache for special client identifiers" do
        expect(OAuthClientConfig::Cache.cache_for("client_id:1234")).to eq(MultiCache.cache)
        expect(OAuthClientConfig::Cache.cache_for("product:1234")).to eq(MultiCache.cache)
      end

      it "uses Rails.cache for other client identifiers" do
        expect(OAuthClientConfig::Cache.cache_for("service_user_key:100001")).to eq(Rails.cache)
        expect(OAuthClientConfig::Cache.cache_for("token:asdfjkl")).to eq(Rails.cache)
      end
    end

    def cache_double
      cache_double = double("cache", fetch: nil, delete: nil)
      cache_contents = {}
      allow(cache_double).to receive(:fetch) do |key, value = nil, &block|
        if cache_contents.key?(key)
          cache_contents[key]
        else
          cache_contents[key] = value || block&.call
        end
      end
      allow(cache_double).to receive(:read_multi) do |*keys, &block|
        result = {}
        keys.each do |key|
          if cache_contents.key?(key)
            result[key] = cache_contents[key]
          else
            result[key] = block&.call(key)
            cache_contents[key] = result[key]
          end
        end
        result
      end
      allow(cache_double).to receive(:write_multi) do |hash|
        hash.each do |k, v|
          cache_contents[k] = v
        end
      end
      allow(cache_double).to receive(:delete) do |key|
        cache_contents.delete(key)
      end
      allow(cache_double).to receive(:clear) do
        cache_contents = {}
      end
      allow(cache_double).to receive(:get) do |key|
        cache_contents[key]
      end
      allow(cache_double).to receive(:debug) { cache_contents }
      cache_double
    end

    describe ".cache_double" do
      it "returns nil when no entry exists" do
        expect(cache_double.fetch("nonexistent")).to be_nil
      end

      it "caches and returns a value" do
        cache = cache_double
        expect(cache.fetch("key", 123)).to eq(123)
        expect(cache.fetch("key", 456)).to eq(123)
        expect(cache.fetch("key") { 789 + 123 }).to eq(123)
      end

      it "deletes an entry" do
        cache = cache_double
        cache.fetch("key", 123)
        cache.delete("key")
        expect(cache.fetch("key")).to be_nil
      end
    end

    describe ".fetch" do
      let(:test_cache) { cache_double }

      before do
        allow(OAuthClientConfig::Cache).to receive(:cache_for).and_return(test_cache)
      end

      it "stores value in memory cache" do
        expect(OAuthClientConfig::Cache.memory_cache).to be_empty
        OAuthClientConfig::Cache.fetch("client_id:1234", "value1")
        expect(OAuthClientConfig::Cache.memory_cache).to include("client_id:1234" => "value1")
      end

      it "returns value" do
        result = OAuthClientConfig::Cache.fetch("client_id:1234", "value1")
        expect(result).to eq("value1")
      end

      it "stores nil sentinel in memory cache" do
        expect(OAuthClientConfig::Cache.memory_cache).to be_empty
        OAuthClientConfig::Cache.fetch("client_id:1234", nil)
        expect(OAuthClientConfig::Cache.memory_cache).to include("client_id:1234" => nil)
      end

      it "fetches from underlying cache if not in memory cache" do
        OAuthClientConfig::Cache.fetch("client_id:1234", "value2")
        expect(test_cache).to have_received(:fetch).with(OAuthClientConfig::Cache.cache_key("client_id:1234"), "value2")
        block = proc { "value3" }
        OAuthClientConfig::Cache.fetch("client_id:4567", &block)
        expect(test_cache).to have_received(:fetch).with(OAuthClientConfig::Cache.cache_key("client_id:4567"), nil, &block)
      end

      it "does not fetch from underlying cache if in memory cache" do
        OAuthClientConfig::Cache.memory_cache["client_id:1234"] = "value4"
        OAuthClientConfig::Cache.fetch("client_id:1234", "value4")
        expect(test_cache).not_to have_received(:fetch)
      end

      it "does not fetch from underlying cache if sentinel in memory cache" do
        OAuthClientConfig::Cache.memory_cache["client_id:1234"] = nil
        OAuthClientConfig::Cache.fetch("client_id:1234", "value4")
        expect(test_cache).not_to have_received(:fetch)
      end
    end

    describe ".fetch_all" do
      let(:ha_cache) { cache_double }
      let(:standard_cache) { cache_double }
      let(:client_identifiers) { ["client_id:1", "token:2"] }

      before do
        allow(OAuthClientConfig::Cache).to receive_messages(ha_cache:, standard_cache:)
      end

      context "when all identifiers are in memory cache" do
        before do
          OAuthClientConfig::Cache.memory_cache["client_id:1"] = "value1"
          OAuthClientConfig::Cache.memory_cache["token:2"] = "value2"
        end

        it "pulls values direct from memory cache" do
          result = OAuthClientConfig::Cache.fetch_all(client_identifiers) { {} }
          expect(result).to eq(["value1", "value2"])
          expect(ha_cache).not_to have_received(:read_multi)
          expect(standard_cache).not_to have_received(:read_multi)
        end

        context "when identifier value is nil" do
          before do
            OAuthClientConfig::Cache.memory_cache["token:2"] = nil
          end

          it "only returns present values" do
            result = OAuthClientConfig::Cache.fetch_all(client_identifiers) { {} }
            expect(result).to eq(["value1"])
            expect(ha_cache).not_to have_received(:read_multi)
            expect(standard_cache).not_to have_received(:read_multi)
          end
        end
      end

      context "when identifiers are in Redis" do
        before do
          ha_cache.fetch(OAuthClientConfig::Cache.cache_key("client_id:1"), "value1")
          standard_cache.fetch(OAuthClientConfig::Cache.cache_key("token:2"), "value2")
        end

        it "pulls values from associated cache" do
          block_called = false
          block = -> { block_called = true }
          result = OAuthClientConfig::Cache.fetch_all(client_identifiers, &block)
          expect(result).to eq(["value1", "value2"])
          expect(block_called).to be false
        end

        context "when some identifiers are not cached" do
          let(:client_identifiers) { ["client_id:1", "token:2", "product:3"] }

          it "falls back to the DB to get them" do
            block = lambda do |missing|
              expect(missing).to eq(["product:3"])
              { "product:3" => "value3" }
            end
            result = OAuthClientConfig::Cache.fetch_all(client_identifiers, &block)
            expect(result).to eq(%w[value1 value2 value3])
          end
        end
      end

      context "in regular operation" do
        before do
          ha_cache.fetch(OAuthClientConfig::Cache.cache_key("client_id:1"), "value1")
          OAuthClientConfig::Cache.memory_cache["token:2"] = "value2"
        end

        let(:block) { ->(_missing) { { "product:3" => "value3" } } }
        let(:client_identifiers) { ["client_id:1", "token:2", "product:3"] }

        it "returns all values" do
          result = OAuthClientConfig::Cache.fetch_all(client_identifiers, &block)
          expect(result).to eq(%w[value1 value2 value3])
        end

        it "writes all values to memory cache" do
          OAuthClientConfig::Cache.fetch_all(client_identifiers, &block)
          expect(OAuthClientConfig::Cache.memory_cache).to include("client_id:1" => "value1", "token:2" => "value2", "product:3" => "value3")
        end

        it "writes all values to the appropriate underlying cache" do
          OAuthClientConfig::Cache.fetch_all(client_identifiers, &block)
          expect(ha_cache).to have_received(:write_multi).with(a_hash_including(OAuthClientConfig::Cache.cache_key("client_id:1") => "value1", OAuthClientConfig::Cache.cache_key("product:3") => "value3"))
          expect(standard_cache).to have_received(:write_multi).with(a_hash_including(OAuthClientConfig::Cache.cache_key("token:2") => "value2"))
          expect(ha_cache.debug).to include(OAuthClientConfig::Cache.cache_key("client_id:1") => "value1", OAuthClientConfig::Cache.cache_key("product:3") => "value3")
          expect(standard_cache.debug).to include(OAuthClientConfig::Cache.cache_key("token:2") => "value2")
        end
      end
    end
  end
end
