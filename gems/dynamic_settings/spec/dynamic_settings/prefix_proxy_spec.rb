# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

module DynamicSettings
  RSpec.describe PrefixProxy do
    let(:proxy) { PrefixProxy.new('foo/bar', service: nil, tree: nil, default_ttl: 3.minutes) }

    after(:each) do
      DynamicSettings.cache.clear(force: true)
    end

    describe '.fetch(key, ttl: @default_ttl)' do
      before(:each) do
        DynamicSettings.cache.reset
      end

      after(:each) do
        DynamicSettings.fallback_recovery_lambda = nil
      end

      it 'must return nil when no value was found' do
        allow(Diplomat::Kv).to receive(:get) { |key| raise Diplomat::KeyNotFound, key }
        expect(proxy.fetch('baz')).to be_nil
      end

      it 'must return the value for the specified key' do
        allow(Diplomat::Kv).to receive(:get).with('', { recurse: true, stale: true }).ordered.and_return([])
        allow(Diplomat::Kv).to receive(:get).with('foo/bar/baz', { stale: true }).ordered.and_return('qux')
        expect(proxy.fetch('baz')).to eq 'qux'
      end

      it 'must fetch the value from consul using the prefix and supplied key' do
        expect(Diplomat::Kv).to receive(:get).with('', { recurse: true, stale: true }).ordered.and_return([])
        expect(Diplomat::Kv).to receive(:get).with('foo/bar/baz', { stale: true }).ordered.and_return(nil)
        expect(Diplomat::Kv).to receive(:get).with('global/foo/bar/baz', { stale: true }).ordered.and_return(nil)
        proxy.fetch('baz')
      end

      it "logs the query when enabled" do
        proxy.query_logging = true
        allow(Diplomat::Kv).to receive(:get).with('', { recurse: true, stale: true }).ordered.and_return([])
        allow(Diplomat::Kv).to receive(:get).with('foo/bar/bang', { stale: true }).ordered.and_return('qux')
        expect(DynamicSettings.logger).to receive(:debug) do |log_message|
          expect(log_message).to match("CONSUL")
          expect(log_message).to match("status:OK")
        end.twice
        expect(proxy.fetch('bang')).to eq 'qux'
      end

      it 'must use the dynamic settings cache for previously fetched values' do
        expect(DynamicSettings.cache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + 'foo/bar/baz').ordered
        expect(DynamicSettings.cache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + '/', expires_in: 3.minutes).ordered
        expect(DynamicSettings.cache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + 'foo/bar/baz', expires_in: 6.minutes).ordered
        expect(DynamicSettings.cache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + 'global/foo/bar/baz', expires_in: 3.minutes).ordered
        proxy.fetch('baz')
      end

      it "must fall back to expired cached values when consul can't be contacted" do
        DynamicSettings.cache.write(DynamicSettings::CACHE_KEY_PREFIX + 'foo/bar/baz', 'qux', expires_in: -3.minutes)
        expect(Diplomat::Kv).to receive(:get).and_raise(Diplomat::KeyNotFound)
        val = proxy.fetch('baz')
        expect(val).to eq 'qux'
      end

      it "must log the connection failure when consul can't be contacted" do
        DynamicSettings.cache.write(DynamicSettings::CACHE_KEY_PREFIX + 'foo/bar/baz', 'qux', expires_in: -3.minutes)
        invoked = false
        DynamicSettings.fallback_recovery_lambda = lambda do |e|
          invoked = true
          expect(e.class).to eq(Diplomat::KeyNotFound)
        end
        allow(Diplomat::Kv).to receive(:get).and_raise(Diplomat::KeyNotFound)
        proxy.fetch('baz')
        expect(invoked).to be_truthy
      end

      it "must raise an exception when consul can't be reached and no previous value is found" do
        expect(Diplomat::Kv).to receive(:get).and_raise(Diplomat::KeyNotFound)
        expect { proxy.fetch('baz') }.to raise_error(Diplomat::KeyNotFound)
      end

      it "falls back to global settings" do
        expect(Diplomat::Kv).to receive(:get).with('', { recurse: true, stale: true }).and_return(nil).ordered
        expect(Diplomat::Kv).to receive(:get).with('foo/bar/baz', { stale: true }).and_return(nil).ordered
        expect(Diplomat::Kv).to receive(:get).with('global/foo/bar/baz', { stale: true }).and_return(42).ordered
        expect(proxy.fetch('baz')).to eq 42
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
        expect(PrefixProxy).to receive(:new).
          with(an_instance_of(String), a_hash_including(default_ttl: 3.minutes))
        proxy.for_prefix('baz')
      end

      it 'must pass on the supplied default ttl' do
        proxy
        expect(PrefixProxy).to receive(:new).
          with(an_instance_of(String), a_hash_including(default_ttl: 5.minutes))
        proxy.for_prefix('baz', default_ttl: 5.minutes)
      end
    end

    describe '#set_keys' do
      let(:kvs) { {foo1: 'bar1', foo2: 'bar2', foo3: 'bar3'} }

      it 'sets multiple key value pairs' do
        expect(Diplomat::Kv).to receive(:txn).with([
          {
            KV: {
              Verb: 'set',
              Key: 'foo/bar/foo1',
              Value: Base64.strict_encode64('bar1')
            }
          },
          {
            KV: {
              Verb: 'set',
              Key: 'foo/bar/foo2',
              Value: Base64.strict_encode64('bar2')
            }
          },
          {
            KV: {
              Verb: 'set',
              Key: 'foo/bar/foo3',
              Value: Base64.strict_encode64('bar3')
            }
          }
        ])
        proxy.set_keys(kvs)
      end

      it 'sets multiple global key value pairs' do
        expect(Diplomat::Kv).to receive(:txn).with([
          {
            KV: {
              Verb: 'set',
              Key: 'global/foo/bar/foo1',
              Value: Base64.strict_encode64('bar1')
            }
          },
          {
            KV: {
              Verb: 'set',
              Key: 'global/foo/bar/foo2',
              Value: Base64.strict_encode64('bar2')
            }
          },
          {
            KV: {
              Verb: 'set',
              Key: 'global/foo/bar/foo3',
              Value: Base64.strict_encode64('bar3')
            }
          }
        ])
        proxy.set_keys(kvs, global: true)
      end
    end
  end
end