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
require_dependency "canvas/dynamic_settings"
require 'imperium/testing' # Not loaded by default


module Canvas
  class DynamicSettings
    RSpec.describe PrefixProxy do
      let(:client) { instance_double(Imperium::KV) }
      let(:proxy) { PrefixProxy.new('foo/bar', service: nil, tree: nil, default_ttl: 3.minutes, kv_client: client) }

      after(:each) do
        LocalCache.clear(force: true)
      end

      describe '.fetch(key, ttl: @default_ttl)' do
        before(:each) do
          # use in-memory cache to avoid redis errors for old expirys.
          # Using redis for local cache results in `ERR invalid expire time in set`
          # when we try to write an already expired key
          allow(ConfigFile).to receive(:load).with("local_cache").and_return({ store: "memory" })
          LocalCache.reset
        end

        it 'must return nil when no value was found' do
          allow(client).to receive(:get)
            .and_return(
              Imperium::Testing.kv_not_found_response(options: [:stale])
            )
          expect(proxy.fetch('baz')).to be_nil
        end

        it 'must return the value for the specified key' do
          allow(client).to receive(:get)
            .and_return(
              Imperium::Testing.kv_get_response(
                body: [
                  { Key: "foo/bar/baz", Value: 'qux'},
                ],
                options: [:stale],
              )
            )
          expect(proxy.fetch('baz')).to eq 'qux'
        end

        it 'must fetch the value from consul using the prefix and supplied key' do
          expect(client).to receive(:get).with('', :recurse, :stale).ordered.and_return(double(status: 200, values: {}))
          expect(client).to receive(:get).with('foo/bar/baz', :stale).ordered.and_return(double(status: 200, values: nil))
          expect(client).to receive(:get).with('global/foo/bar/baz', :stale).ordered.and_return(double(status: 200, values: nil))
          proxy.fetch('baz')
        end

        it "logs the query when enabled" do
          proxy.query_logging = true
          allow(client).to receive(:get).and_return(
            Imperium::Testing.kv_get_response(
              body: [
                { Key: "foo/bar/bang", Value: 'qux'},
              ],
              options: [:stale],
            )
          )
          expect(Rails.logger).to receive(:debug) do |log_message|
            expect(log_message).to match("CONSUL")
            expect(log_message).to match("status:200")
          end.twice
          expect(proxy.fetch('bang')).to eq 'qux'
        end

        it "raises an error on bad statuses" do
          allow(client).to receive(:get).and_return(double(status: 500, values: nil))
          expect { proxy.fetch('bang') }.to raise_error(UnexpectedConsulResponse)
        end

        it 'must use the dynamic settings cache for previously fetched values' do
          expect(LocalCache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + 'foo/bar/baz').ordered
          expect(LocalCache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + '/', expires_in: 3.minutes).ordered
          expect(LocalCache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + 'foo/bar/baz', expires_in: 6.minutes).ordered
          expect(LocalCache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + 'global/foo/bar/baz', expires_in: 3.minutes).ordered
          proxy.fetch('baz')
        end

        it "must fall back to expired cached values when consul can't be contacted" do
          LocalCache.write(DynamicSettings::CACHE_KEY_PREFIX + 'foo/bar/baz', 'qux', expires_in: -3.minutes)
          expect(client).to receive(:get).and_raise(Imperium::TimeoutError)
          val = proxy.fetch('baz')
          expect(val).to eq 'qux'
        end

        it "must log the connection failure when consul can't be contacted" do
          LocalCache.write(DynamicSettings::CACHE_KEY_PREFIX + 'foo/bar/baz', 'qux', expires_in: -3.minutes)
          expect(Canvas::Errors).to receive(:capture_exception).
            with(:consul, an_instance_of(Imperium::TimeoutError))
          allow(client).to receive(:get).and_raise(Imperium::TimeoutError)
          proxy.fetch('baz')
        end

        it "must raise an exception when consul can't be reached and no previous value is found" do
          expect(client).to receive(:get).and_raise(Imperium::TimeoutError)
          expect { proxy.fetch('baz') }.to raise_error(Imperium::TimeoutError)
        end

        it "falls back to global settings" do
          empty_mock = double(status: 404, values: nil)
          mock = double(status: 200, values: 42)
          expect(client).to receive(:get).with('', :recurse, :stale).and_return(empty_mock).ordered
          expect(client).to receive(:get).with('foo/bar/baz', :stale).and_return(empty_mock).ordered
          expect(client).to receive(:get).with('global/foo/bar/baz', :stale).and_return(mock).ordered
          expect(proxy.fetch('baz')).to eq 42
        end
      end

      describe 'with redis local cache' do
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
          # will get cleared by top-level "after" block
          LocalCache.reset
        end

        let(:proxy) { PrefixProxy.new('test/prefix', service: 'test_svc', tree: 'test_tree', environment: 'test_env', default_ttl: 3.minutes, kv_client: client) }

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
          skip ('FOO-1030 10/5/2020')
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

      describe 'for_prefix(prefix_extension, default_ttl: @default_ttl)' do
        it 'must instantiate a new proxy with the supplied prefix extension appended to the current prefix' do
          new_proxy = proxy.for_prefix('baz')
          expect(new_proxy).to be_a PrefixProxy
          expect(new_proxy.prefix).to eq 'foo/bar/baz'
        end

        it "must pass on the current instance's default ttl if not supplied" do
          proxy
          expect(PrefixProxy).to receive(:new)
            .with(an_instance_of(String), a_hash_including(default_ttl: 3.minutes))
          proxy.for_prefix('baz')
        end

        it 'must pass on the supplied default ttl' do
          proxy
          expect(PrefixProxy).to receive(:new)
            .with(an_instance_of(String), a_hash_including(default_ttl: 5.minutes))
          proxy.for_prefix('baz', default_ttl: 5.minutes)
        end

        it 'must pass on the kv client from the receiving proxy' do
          proxy
          expect(PrefixProxy).to receive(:new)
            .with(an_instance_of(String), a_hash_including(kv_client: client))
          proxy.for_prefix('baz')
        end
      end

      describe '#set_keys' do
        let(:kvs) { {foo1: 'bar1', foo2: 'bar2', foo3: 'bar3'} }

        it 'sets multiple key value pairs' do
          transaction_double = double(:transaction)
          expect(transaction_double).to receive(:set).with('foo/bar/foo1', 'bar1')
          expect(transaction_double).to receive(:set).with('foo/bar/foo2', 'bar2')
          expect(transaction_double).to receive(:set).with('foo/bar/foo3', 'bar3')
          allow(client).to receive(:transaction).and_yield(transaction_double)
          proxy.set_keys(kvs)
        end

        it 'sets multiple global key value pairs' do
          transaction_double = double(:transaction)
          expect(transaction_double).to receive(:set).with('global/foo/bar/foo1', 'bar1')
          expect(transaction_double).to receive(:set).with('global/foo/bar/foo2', 'bar2')
          expect(transaction_double).to receive(:set).with('global/foo/bar/foo3', 'bar3')
          allow(client).to receive(:transaction).and_yield(transaction_double)
          proxy.set_keys(kvs, global: true)
        end
      end
    end
  end
end
