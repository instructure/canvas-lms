# frozen_string_literal: true

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
require "dynamic_settings"

# This looks like a test for a class that is in another
# package, and it IS, but the reason it exists is that
# we're testing specifically the behavior of the
# dynamic_settings gem when we give it a caching
# implementation that works on a redis store
RSpec.describe "DynamicSettings::PrefixProxy with redis local cache" do
  let(:redis_conf_hash) do
    rc = CanvasCache::Redis.config
    {
      store: "redis",
      redis_url: Array(rc.fetch("url", "redis://redis")).first,
      redis_db: rc.fetch("database", 1)
    }
  end

  let(:proxy) do
    DynamicSettings::PrefixProxy.new("test/prefix",
                                     service: "test_svc",
                                     tree: "test_tree",
                                     environment: "test_env",
                                     default_ttl: 3.minutes)
  end

  before do
    skip("Must have a local redis available to run this spec") unless Canvas.redis_enabled?
    DynamicSettings.cache = LocalCache
    allow(ConfigFile).to receive(:load).with("local_cache").and_return(redis_conf_hash)
    LocalCache.reset
  end

  after do
    LocalCache.clear(force: true)
  end

  it "caches tree values from client" do
    expect(Diplomat::Kv).to receive(:get_all).with("test_tree/test_svc/test_env", { recurse: true, stale: true }).and_return([
                                                                                                                               {
                                                                                                                                 key: "test_tree/test_svc/test_env/test/prefix/svc_config/app-host",
                                                                                                                                 value: "http://test-host"
                                                                                                                               },
                                                                                                                               {
                                                                                                                                 key: "test_tree/test_svc/test_env/test/prefix/svc_config/app-secret",
                                                                                                                                 value: "sekret"
                                                                                                                               }
                                                                                                                             ]).ordered
    # shouldn't need to get a specific key because it's already populated in the cache
    expect(Diplomat::Kv).to_not receive(:get).with("test_tree/test_svc/test_env/test/prefix/svc_config/app-host", { stale: true })
    expect(Diplomat::Kv).to_not receive(:get).with("test_tree/test_svc/test_env/test/prefix/svc_config/app-secret")
    output = proxy["svc_config/app-host"]
    expect(output).to eq("http://test-host")
    expect(proxy["svc_config/app-secret"]).to eq("sekret")
  end

  it "can handle a cache clear" do
    skip("10/5/2020 FOO-1030")

    expect(Diplomat::Kv).to receive(:get_all).with("test_tree/test_svc/test_env", { recurse: true, stale: true }).and_return([
                                                                                                                               {
                                                                                                                                 key: "test_tree/test_svc/test_env/test/prefix/svc_config/app-host",
                                                                                                                                 value: "http://test-host"
                                                                                                                               },
                                                                                                                               {
                                                                                                                                 key: "test_tree/test_svc/test_env/test/prefix/svc_config/app-secret",
                                                                                                                                 value: "sekret"
                                                                                                                               }
                                                                                                                             ]).ordered
    expect(Diplomat::Kv).to_not receive(:get).with("test_tree/test_svc/test_env/test/prefix/svc_config/app-host", { stale: true })
    expect(Diplomat::Kv).to receive(:get).with("test_tree/test_svc/test_env/test/prefix/svc_config/app-secret", { stale: true }).and_return("sekret").ordered
    output = proxy["svc_config/app-host"]
    expect(output).to eq("http://test-host")
    # CACHE CLEAR, but force race condition
    LocalCache.clear
    LocalCache.write("dynamic_settings/test_tree/test_svc/test_env/", true)
    expect(proxy["svc_config/app-secret"]).to eq("sekret")
  end
end
