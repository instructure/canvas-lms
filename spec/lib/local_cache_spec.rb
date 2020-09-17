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
    LocalCache.clear
    LocalCache.reset
  end

  it "falls back to memory cache if unconfigured" do
    allow(ConfigFile).to receive(:load).with("local_cache").and_return(nil)
    LocalCache.reset
    expect(LocalCache.cache.class).to eq(Canvas::Cache::FallbackMemoryCache)
  end

  describe "with redis" do
    before(:each) do
      allow(ConfigFile).to receive(:load).with("local_cache").and_return({
        store: "redis",
        redis_host: "redis",
        redis_port: 6379,
        redis_db: 8 # intentionally one probably not used elsewhere
      })
      LocalCache.reset
    end

    it "uses a redis store" do
      expect(LocalCache.cache.class).to eq(Canvas::Cache::LocalRedisCache)
    end

    it "will allow you to clear because it's local" do
      LocalCache.write("test_key", "test_value")
      expect{ LocalCache.clear }.to_not raise_error
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

  end
end