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
require "spec_helper"

module DynamicSettings
  RSpec.describe PrefixProxy do
    let(:proxy) do
      PrefixProxy.new(
        "foo/bar", service: nil, tree: nil, default_ttl: 3.minutes, data_center: "iad-test"
      )
    end

    after do
      DynamicSettings.cache.clear(force: true)
    end

    describe ".fetch(key, ttl: @default_ttl)" do
      before do
        DynamicSettings.cache.reset
      end

      after do
        DynamicSettings.fallback_recovery_lambda = nil
      end

      let(:failsafe_cache) { Pathname.new(__dir__).join("config") }

      it "must return nil when no value was found" do
        allow(Diplomat::Kv).to receive(:get_all) { |key| raise Diplomat::KeyNotFound, key }
        allow(Diplomat::Kv).to receive(:get) { |key| raise Diplomat::KeyNotFound, key }
        expect(proxy.fetch("baz")).to be_nil
      end

      it "must return the value for the specified key" do
        allow(Diplomat::Kv).to receive(:get_all).with("", { recurse: true, stale: true }).and_return([])
        allow(Diplomat::Kv).to receive(:get).with("foo/bar/baz", { stale: true }).and_return("qux")
        expect(proxy.fetch("baz")).to eq "qux"
      end

      it "must fetch the value from consul using the prefix and supplied key" do
        expect(Diplomat::Kv).to receive(:get_all).with("", { recurse: true, stale: true }).and_return([])
        expect(Diplomat::Kv).to receive(:get).with("foo/bar/baz", { stale: true }).ordered.and_return(nil)
        expect(Diplomat::Kv).to receive(:get).with("global/foo/bar/baz", { stale: true }).ordered.and_return(nil)
        proxy.fetch("baz")
      end

      it "logs the query when enabled" do
        proxy.query_logging = true
        allow(Diplomat::Kv).to receive(:get_all).with("", { recurse: true, stale: true }).and_return([])
        allow(Diplomat::Kv).to receive(:get).with("foo/bar/bang", { stale: true }).and_return("qux")
        expect(DynamicSettings.logger).to receive(:debug) do |log_message|
          expect(log_message).to match("CONSUL")
          expect(log_message).to match("status:OK")
        end.twice
        expect(proxy.fetch("bang")).to eq "qux"
      end

      it "must use the dynamic settings cache for previously fetched values" do
        expect(DynamicSettings.cache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + "foo/bar/baz").ordered
        expect(DynamicSettings.cache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + "/", expires_in: 3.minutes).ordered
        expect(DynamicSettings.cache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + "foo/bar/baz", expires_in: 6.minutes).ordered
        expect(DynamicSettings.cache).to receive(:fetch).with(DynamicSettings::CACHE_KEY_PREFIX + "global/foo/bar/baz", expires_in: 3.minutes).ordered
        proxy.fetch("baz")
      end

      it "must fall back to expired cached values when consul can't be contacted" do
        DynamicSettings.cache.write(DynamicSettings::CACHE_KEY_PREFIX + "foo/bar/baz", "qux", expires_in: 0)
        expect(Diplomat::Kv).to receive(:get_all).and_raise(Diplomat::KeyNotFound)
        Timecop.travel(3.minutes) do
          val = proxy.fetch("baz")
          expect(val).to eq "qux"
        end
      end

      it "must log the connection failure when consul can't be contacted" do
        DynamicSettings.cache.write(DynamicSettings::CACHE_KEY_PREFIX + "foo/bar/baz", "qux", expires_in: 0)
        invoked = false
        DynamicSettings.fallback_recovery_lambda = lambda do |e|
          invoked = true
          expect(e.class).to eq(Diplomat::KeyNotFound)
        end
        allow(Diplomat::Kv).to receive(:get_all).and_raise(Diplomat::KeyNotFound)
        Timecop.travel(3.minutes) do
          proxy.fetch("baz")
          expect(invoked).to be_truthy
        end
      end

      it "must raise an exception when consul can't be reached and no previous value is found" do
        expect(Diplomat::Kv).to receive(:get_all).and_raise(Diplomat::KeyNotFound)
        expect { proxy.fetch("baz") }.to raise_error(Diplomat::KeyNotFound)
      end

      it "returns the failsafe value when consul can't be reached and no previous value is found" do
        expect(Diplomat::Kv).to receive(:get_all).twice.and_raise(Diplomat::KeyNotFound)
        expect(proxy.fetch("baz", failsafe: nil)).to be_nil
        expect(proxy.fetch("baz", failsafe: "a")).to eq "a"
      end

      it "returns from the failsafe cache when consul can't be reached and no previous value is found" do
        allow(Diplomat::Kv).to receive_messages(get_all: nil, get: nil)

        expect(proxy.fetch("baz", failsafe_cache:)).to be_nil
        DynamicSettings.cache.clear
        expect(Diplomat::Kv).to receive(:get_all).and_raise(Diplomat::KeyNotFound)
        expect(proxy.fetch("baz", failsafe_cache:)).to be_nil
      end

      it "falls back to global settings" do
        expect(Diplomat::Kv).to receive(:get_all).with("", { recurse: true, stale: true }).and_return(nil).ordered
        expect(Diplomat::Kv).to receive(:get).with("foo/bar/baz", { stale: true }).and_return(nil).ordered
        expect(Diplomat::Kv).to receive(:get).with("global/foo/bar/baz", { stale: true }).and_return(42).ordered
        expect(proxy.fetch("baz")).to eq 42
      end

      context "with retries" do
        before do
          allow(proxy).to receive_messages(retry_limit: 2, retry_base: 1.4)
        end

        it "retries if there is an initial error" do
          expect(Diplomat::Kv).to receive(:get_all).and_raise(Diplomat::KeyNotFound).ordered
          expect(proxy).to receive(:sleep).with(1.4)
          expect(Diplomat::Kv).to receive(:get_all).and_return([]).ordered
          allow(Diplomat::Kv).to receive(:get).with("foo/bar/baz", { stale: true }).and_return("qux")

          expect(proxy.fetch("baz")).to eq "qux"
        end

        it "still raises errors if retries fail" do
          expect(Diplomat::Kv).to receive(:get_all).and_raise(Diplomat::KeyNotFound).twice
          expect(proxy).to receive(:sleep).with(1.4)

          expect { proxy.fetch("baz") }.to raise_error(Diplomat::KeyNotFound)
        end

        context "with circuit breaker" do
          let(:circuit_breaker) { CircuitBreaker.new }

          before do
            allow(proxy).to receive(:circuit_breaker).and_return(circuit_breaker)
          end

          it "fails immediately if the circuit breaker is tripped" do
            allow(circuit_breaker).to receive(:tripped?).and_return(true)
            expect(Diplomat::Kv).not_to receive(:get_all)
            expect(proxy).not_to receive(:sleep)

            expect { proxy.fetch("baz") }.to raise_error(Diplomat::UnknownStatus)
          end

          it "trips the circuit breaker" do
            expect(Diplomat::Kv).to receive(:get_all).and_raise(Diplomat::KeyNotFound).twice
            expect(proxy).to receive(:sleep).with(1.4)

            expect { proxy.fetch("baz") }.to raise_error(Diplomat::KeyNotFound)
            expect(circuit_breaker).to be_tripped
          end
        end
      end
    end

    describe "for_prefix(prefix_extension, default_ttl: @default_ttl)" do
      it "must instantiate a new proxy with the supplied prefix extension appended to the current prefix" do
        new_proxy = proxy.for_prefix("baz")
        expect(new_proxy).to be_a PrefixProxy
        expect(new_proxy.prefix).to eq "foo/bar/baz"
      end

      it "must pass on the current instance's default ttl if not supplied" do
        proxy
        expect(PrefixProxy).to receive(:new)
          .with(an_instance_of(String), a_hash_including(default_ttl: 3.minutes))
        proxy.for_prefix("baz")
      end

      it "must pass on the supplied default ttl" do
        proxy
        expect(PrefixProxy).to receive(:new)
          .with(an_instance_of(String), a_hash_including(default_ttl: 5.minutes))
        proxy.for_prefix("baz", default_ttl: 5.minutes)
      end
    end

    describe "#set_keys" do
      let(:kvs) { { foo1: "bar1", foo2: "bar2", foo3: "bar3" } }

      it "sets multiple key value pairs" do
        expect(Diplomat::Kv).to receive(:txn).with([
                                                     {
                                                       "KV" => {
                                                         "Verb" => "set",
                                                         "Key" => "foo/bar/foo1",
                                                         "Value" => "bar1"
                                                       }
                                                     },
                                                     {
                                                       "KV" => {
                                                         "Verb" => "set",
                                                         "Key" => "foo/bar/foo2",
                                                         "Value" => "bar2"
                                                       }
                                                     },
                                                     {
                                                       "KV" => {
                                                         "Verb" => "set",
                                                         "Key" => "foo/bar/foo3",
                                                         "Value" => "bar3"
                                                       }
                                                     }
                                                   ],
                                                   {})
        proxy.set_keys(kvs)
      end

      it "sets multiple global key value pairs" do
        expect(Diplomat::Kv).to receive(:txn).with([
                                                     {
                                                       "KV" => {
                                                         "Verb" => "set",
                                                         "Key" => "global/foo/bar/foo1",
                                                         "Value" => "bar1"
                                                       }
                                                     },
                                                     {
                                                       "KV" => {
                                                         "Verb" => "set",
                                                         "Key" => "global/foo/bar/foo2",
                                                         "Value" => "bar2"
                                                       }
                                                     },
                                                     {
                                                       "KV" => {
                                                         "Verb" => "set",
                                                         "Key" => "global/foo/bar/foo3",
                                                         "Value" => "bar3"
                                                       }
                                                     }
                                                   ],
                                                   { dc: "iad-test" })
        proxy.set_keys(kvs, global: true)
      end
    end
  end
end
