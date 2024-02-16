# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe ActiveSupport::Cache::HaStore do
  before do
    skip unless Canvas.redis_enabled?
  end

  let(:store) { ActiveSupport::Cache::HaStore.new(url: Canvas.redis.id, expires_in: 5.minutes.to_i, race_condition_ttl: 7.days.to_i, consul_event: "invalidate") }

  describe "#delete" do
    it "triggers a consul event when configured" do
      # will get called twice; once with rails52: prefix, once without
      expect(Diplomat::Event).to receive(:fire).with("invalidate", match(/mykey$/), nil, nil, nil, nil).exactly(SUPPORTED_RAILS_VERSIONS.count).times
      store.delete("mykey")
    end
  end

  describe "#delete_matched" do
    it "triggers a consul event when configured" do
      expect(Diplomat::Event).to receive(:fire).with("invalidate", match(%r{^DELETE_MATCHED|rails\?\?:mykey/\*$}), nil, nil, nil, nil)
      store.delete_matched("mykey/*")
    end
  end

  describe "consume_consul_events" do
    it "works" do
      # check that Canvas.redis is equivalent to Redis.new that consume_consule_events uses
      # I would normally compare against `id`, but that might have localhost vs. 127.0.0.1
      redis = Redis.new(connect_timeout: 0.5)
      secret_key = SecureRandom.uuid
      Canvas.redis.set(secret_key, "1", ex: 5)
      skip "Can't run this spec unless redis is default configured" unless (redis.get(secret_key) rescue nil) == "1"
      consul_event_id = SecureRandom.uuid

      Bundler.with_unbundled_env do
        payload = [{ ID: consul_event_id, Payload: Base64.strict_encode64(secret_key) }].to_json

        `echo #{Shellwords.escape(payload)} | #{Rails.root}/script/consume_consul_events`
        expect($?).to be_success
      end
      expect(redis.get(secret_key)).to be_nil
      expect(redis.zrank("consul_events", consul_event_id)).not_to be_nil
    end

    it "deletes single keys" do
      # check that Canvas.redis is equivalent to Redis.new that consume_consule_events uses
      # I would normally compare against `id`, but that might have localhost vs. 127.0.0.1
      redis = Redis.new(connect_timeout: 0.5)
      secret_key = "prefix1/#{SecureRandom.uuid}"
      Canvas.redis.set(secret_key, "1", ex: 5)
      secret_key2 = "prefix1/#{SecureRandom.uuid}"
      Canvas.redis.set(secret_key2, "1", ex: 5)
      secret_key3 = "prefix2/#{SecureRandom.uuid}"
      Canvas.redis.set(secret_key3, "1", ex: 5)
      skip "Can't run this spec unless redis is default configured" unless (redis.get(secret_key) rescue nil) == "1"
      consul_event_id = SecureRandom.uuid

      Bundler.with_unbundled_env do
        payload = [{ ID: consul_event_id, Payload: Base64.strict_encode64("DELETE_MATCHED|prefix1/*") }].to_json

        `echo #{Shellwords.escape(payload)} | #{Rails.root}/script/consume_consul_events`
        expect($?).to be_success
      end
      expect(redis.get(secret_key)).to be_nil
      expect(redis.get(secret_key2)).to be_nil
      expect(redis.get(secret_key3)).to eq("1")
      expect(redis.zrank("consul_events", consul_event_id)).not_to be_nil
    end

    it "deletes maching keys" do
      # check that Canvas.redis is equivalent to Redis.new that consume_consule_events uses
      # I would normally compare against `id`, but that might have localhost vs. 127.0.0.1
      redis = Redis.new(connect_timeout: 0.5)
      secret_key = SecureRandom.uuid
      Canvas.redis.set(secret_key, "1", ex: 5)
      secret_key2 = SecureRandom.uuid
      Canvas.redis.set(secret_key2, "1", ex: 5)
      skip "Can't run this spec unless redis is default configured" unless (redis.get(secret_key) rescue nil) == "1"
      consul_event_id = SecureRandom.uuid

      Bundler.with_unbundled_env do
        payload = [{ ID: consul_event_id, Payload: Base64.strict_encode64("DELETE|#{secret_key}") }].to_json

        `echo #{Shellwords.escape(payload)} | #{Rails.root}/script/consume_consul_events`
        expect($?).to be_success
      end
      expect(redis.get(secret_key)).to be_nil
      expect(redis.get(secret_key2)).to eq("1")
      expect(redis.zrank("consul_events", consul_event_id)).not_to be_nil
    end

    it "cleared everything with FLUSHDB" do
      # check that Canvas.redis is equivalent to Redis.new that consume_consule_events uses
      # I would normally compare against `id`, but that might have localhost vs. 127.0.0.1
      redis = Redis.new(connect_timeout: 0.5)
      secret_key = SecureRandom.uuid
      secret_key2 = SecureRandom.uuid
      Canvas.redis.set(secret_key, "1", ex: 5)
      Canvas.redis.set(secret_key2, "1", ex: 5)
      skip "Can't run this spec unless redis is default configured" unless (redis.get(secret_key) rescue nil) == "1"
      consul_event_id = SecureRandom.uuid

      Bundler.with_unbundled_env do
        payload = [{ ID: consul_event_id, Payload: Base64.strict_encode64("FLUSHDB") }].to_json

        `echo #{Shellwords.escape(payload)} | #{Rails.root}/script/consume_consul_events`
        expect($?).to be_success
      end
      expect(redis.get(secret_key)).to be_nil
      expect(redis.get(secret_key2)).to be_nil
      # This is reset after clearing the db, which is important so we don't repeatedly clear
      expect(redis.zrank("consul_events", consul_event_id)).not_to be_nil
    end
  end

  context "Account cache register" do
    specs_require_cache(:redis_cache_store)

    before do
      allow(MultiCache).to receive(:cache).and_return(store)
      allow(Diplomat::Event).to receive(:fire)
    end

    it "uses MultiCache as store for feature_flags cache_key" do
      Timecop.freeze do
        now = Time.now.utc.to_fs(Account.cache_timestamp_format)
        base_key = Account.base_cache_register_key_for(Account.site_admin)
        full_key = "{#{base_key}}/feature_flags"
        expect(Canvas::CacheRegister.lua).to receive(:run).with(:get_key, [full_key], [now], store.redis).and_return("cool beans")
        expect(Account.site_admin.cache_key(:feature_flags)).to eq("accounts/#{Account.site_admin.global_id}-cool beans")
        # doesn't use it for other key types
        expect(Canvas::CacheRegister.lua).to receive(:run).with(:get_key, ["{#{base_key}}/global_navigation"], [now], Canvas.redis).and_return(now)
        expect(Account.site_admin.cache_key(:global_navigation)).to eq("accounts/#{Account.site_admin.global_id}-#{now}")
      end
    end

    it "properly invalidates feature_flags cache_key" do
      Timecop.freeze do
        key1 = Account.site_admin.cache_key(:feature_flags)
        Timecop.travel(1)
        expect(Account.site_admin.cache_key(:feature_flags)).to eq key1
        Timecop.travel(1)
        expect(Canvas.redis).to_not receive(:del)
        Account.site_admin.clear_cache_key(:feature_flags)
        expect(Account.site_admin.cache_key(:feature_flags)).not_to eq key1
      end
    end
  end
end
