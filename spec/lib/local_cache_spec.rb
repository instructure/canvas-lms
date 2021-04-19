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

require 'spec_helper'

describe LocalCache do
  after(:each) do
    LocalCache.clear(force: true)
    LocalCache.reset
  end

  it "falls back to memory cache if unconfigured" do
    allow(ConfigFile).to receive(:load).with("local_cache").and_return(nil)
    LocalCache.reset
    expect(LocalCache.cache.class).to eq(Canvas::Cache::FallbackMemoryCache)
  end

  describe "with redis" do
    let(:redis_conf_hash) do
      rc = Canvas.redis_config
      {
        store: "redis",
        redis_url: rc.fetch("servers", ["redis://redis"]).first,
        redis_db: rc.fetch("database", 1)
      }
    end

    before(:each) do
      skip("Must have a local redis available to run this spec") unless Canvas.redis_enabled?
      allow(ConfigFile).to receive(:load).with("local_cache").and_return(redis_conf_hash)
      LocalCache.reset
      LocalCache.clear
    end

    after(:each) do
      LocalCache.clear
    end

    it "uses a redis store" do
      expect(LocalCache.cache.class).to eq(Canvas::Cache::LocalRedisCache)
    end

    it "will allow you to clear because it's local" do
      LocalCache.write("test_key", "test_value")
      expect{ LocalCache.clear(force: true) }.to_not raise_error
      expect(LocalCache.read("test_key")).to be_nil
    end

    it "acts like a cache" do
      LocalCache.write("test_key", "test_value")
      expect(LocalCache.read("test_key")).to eq("test_value")
    end

    it "does stale rescue caching" do
      LocalCache.write("test_key", "test_value", expires_in: 2)
      Timecop.travel(5) do
        expect(LocalCache.read("test_key")).to be_nil
        expect(LocalCache.fetch_without_expiration("test_key")).to eq("test_value")
      end
    end

    it "writes a set of keys all at once" do
      data_set = {
        "keya" => "vala",
        "keyb" => "valb",
        "keyc" => "valc",
      }
      LocalCache.write_set(data_set, ttl: 1)
      expect(LocalCache.read("keya")).to eq("vala")
      expect(LocalCache.read("keyb")).to eq("valb")
      expect(LocalCache.read("keyc")).to eq("valc")
      Timecop.travel(5) do
        expect(LocalCache.read("keya")).to be_nil
        expect(LocalCache.read("keyb")).to be_nil
        expect(LocalCache.read("keyc")).to be_nil
      end
    end
  end

  describe "in memory" do
    before(:each) do
      allow(ConfigFile).to receive(:load).with("local_cache").and_return({ store: "memory" })
      LocalCache.reset
    end

    it "uses a mem store" do
      expect(LocalCache.cache.class).to eq(Canvas::Cache::FallbackMemoryCache)
    end

    it "acts like a cache" do
      LocalCache.write("test_key", "test_value")
      expect(LocalCache.read("test_key")).to eq("test_value")
    end

    it "does stale rescue caching" do
      LocalCache.write("test_key", "test_value", expires_in: 2)
      Timecop.travel(5) do
        expect(LocalCache.read("test_key")).to be_nil
        expect(LocalCache.fetch_without_expiration("test_key")).to eq("test_value")
      end
    end

    it "writes a set of keys all at once" do
      data_set = {
        "keya" => "vala",
        "keyb" => "valb",
        "keyc" => "valc",
      }
      LocalCache.write_set(data_set, ttl: 30)
      expect(LocalCache.read("keya")).to eq("vala")
      expect(LocalCache.read("keyb")).to eq("valb")
      expect(LocalCache.read("keyc")).to eq("valc")
      Timecop.travel(60) do
        expect(LocalCache.read("keya")).to be_nil
        expect(LocalCache.read("keyb")).to be_nil
        expect(LocalCache.read("keyc")).to be_nil
      end
    end

    it "doesn't care about the force parameter" do
      LocalCache.write("test_key", "test_value", expires_in: 2)
      LocalCache.clear(force: true)
      expect(LocalCache.read("test_key")).to be_nil
      LocalCache.write("test_key", "test_value", expires_in: 2)
      LocalCache.clear(force: false)
      expect(LocalCache.read("test_key")).to be_nil
    end
  end
end