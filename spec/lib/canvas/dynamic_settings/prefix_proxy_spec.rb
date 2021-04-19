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
require 'spec_helper'
require 'dynamic_settings'
require 'imperium/testing' # Not loaded by default

# This looks like a test for a class that is in another
# package, and it IS, but the reason it exists is that
# we're testing specifically the behavior of the
# dynamic_settings gem when we give it a caching
# implementation that works on a redis store
RSpec.describe "DynamicSettings::PrefixProxy with redis local cache" do
  let(:redis_conf_hash) do
    rc = Canvas.redis_config
    {
      store: "redis",
      redis_url: rc.fetch("servers", ["redis://redis"]).first,
      redis_db: rc.fetch("database", 1)
    }
  end

  let(:client) { instance_double(Imperium::KV) }
  let(:proxy) do
    DynamicSettings::PrefixProxy.new('test/prefix',
                                     service: 'test_svc',
                                     tree: 'test_tree',
                                     environment: 'test_env',
                                     default_ttl: 3.minutes,
                                     kv_client: client)
  end

  before(:each) do
    skip("Must have a local redis available to run this spec") unless Canvas.redis_enabled?
    DynamicSettings.cache = LocalCache
    allow(ConfigFile).to receive(:load).with("local_cache").and_return(redis_conf_hash)
    LocalCache.reset
  end

  after(:each) do
    LocalCache.clear(force: true)
  end

  it "caches tree values from client" do
    mock = double(status: 200, values: {
      'test' => {
        'prefix' => {
          'svc_config' => {
            'app-host' => 'http://test-host',
            'app-secret' => 'sekret'
          }
        }
      }
    })
    expect(client).to receive(:get).with('test_tree/test_svc/test_env', :recurse, :stale).and_return(mock).ordered
    # shouldn't need to get a specific key because it's already populated in the cache
    expect(client).to_not receive(:get).with('test_tree/test_svc/test_env/test/prefix/svc_config/app-host', :stale)
    expect(client).to_not receive(:get).with('test_tree/test_svc/test_env/test/prefix/svc_config/app-secret', :stale)
    output = proxy['svc_config/app-host']
    expect(output).to eq('http://test-host')
    expect(proxy['svc_config/app-secret']).to eq('sekret')
  end

  it "can handle a cache clear" do
    skip('10/5/2020 FOO-1030')
    mock = double(status: 200, values: {
      'test' => {
        'prefix' => {
          'svc_config' => {
            'app-host' => 'http://test-host',
            'app-secret' => 'sekret'
          }
        }
      }
    })
    sub_mock = double(status: 200, values: 'sekret')
    expect(client).to receive(:get).with('test_tree/test_svc/test_env', :recurse, :stale).and_return(mock).ordered
    expect(client).to_not receive(:get).with('test_tree/test_svc/test_env/test/prefix/svc_config/app-host', :stale)
    expect(client).to receive(:get).with('test_tree/test_svc/test_env/test/prefix/svc_config/app-secret', :stale).and_return(sub_mock).ordered
    output = proxy['svc_config/app-host']
    expect(output).to eq('http://test-host')
    # CACHE CLEAR, but force race condition
    LocalCache.clear
    LocalCache.write("dynamic_settings/test_tree/test_svc/test_env/", true)
    expect(proxy['svc_config/app-secret']).to eq('sekret')
  end
end
