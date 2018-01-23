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
        Cache.reset!
      end

      describe '.fetch(key, ttl: @default_ttl)' do
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
          expect(client).to receive(:get).with('global/foo/bar/baz', :stale).ordered.and_return(double(status: 200, values: nil))
          proxy.fetch('baz')
        end

        it 'must use the dynamic settings cache for previously fetched values' do
          expect(Cache).to receive(:fetch).with('/', ttl: 3.minutes).ordered
          expect(Cache).to receive(:fetch).with('foo/bar/baz').ordered
          expect(Cache).to receive(:fetch).with('global/foo/bar/baz', ttl: 3.minutes).ordered
          proxy.fetch('baz')
        end

        it "must fall back to expired cached values when consul can't be contacted" do
          Cache.store['foo/bar/baz'] = Cache::Value.new('qux', 3.minutes.ago)
          expect(client).to receive(:get).and_raise(Imperium::TimeoutError)
          val = proxy.fetch('baz')
          expect(val).to eq 'qux'
        end

        it "must log the connection failure when consul can't be contacted" do
          Cache.store['foo/bar/baz'] = Cache::Value.new('qux', 3.minutes.ago)
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
          expect(client).to receive(:get).with('', :recurse, :stale).and_return(nil).ordered
          mock = double(status: 200, values: 42)
          expect(client).to receive(:get).with('global/foo/bar/baz', :stale).and_return(mock).ordered
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
    end
  end
end
