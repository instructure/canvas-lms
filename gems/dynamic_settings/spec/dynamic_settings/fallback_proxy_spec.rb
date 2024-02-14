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
require "fixtures/setting"

module DynamicSettings
  RSpec.describe FallbackProxy do
    let(:fallback_data) do
      {
        foo: "bar",
        baz: {
          qux: 42
        }
      }
    end

    let(:proxy) { FallbackProxy.new(fallback_data) }
    let(:foo_key) { FallbackProxy::PERSISTENCE_FLAG + FallbackProxy::PERSISTED_TREE + "/foo" }
    let(:baz_key) { FallbackProxy::PERSISTENCE_FLAG + "baz/qux" }
    let(:foo_setting) { Setting.new(foo_key, "override") }
    let(:baz_setting) { Setting.new(baz_key, "override") }

    describe "#initalize" do
      before { allow(Setting).to receive(:where).and_return([foo_setting]) }

      it "must store an empty hash when initialized with nil" do
        proxy = FallbackProxy.new(nil)
        expect(proxy.data).to eq({})
      end

      describe "with ignore_fallback_overrides: true" do
        it "does not load overrides from Settings" do
          proxy = FallbackProxy.new(fallback_data, FallbackProxy::PERSISTED_TREE, ignore_fallback_overrides: true)
          expect(proxy[:foo]).to eq "bar"
        end
      end

      describe "with ignore_fallback_overrides: false" do
        it "loads overrides from Settings for PERSISTED_TREE" do
          proxy = FallbackProxy.new(fallback_data, FallbackProxy::PERSISTED_TREE, ignore_fallback_overrides: false)
          expect(proxy[:foo]).to eq "override"
        end

        it "does not load overrides from Settings for other trees" do
          allow(Setting).to receive(:where).and_return([baz_setting])
          proxy = FallbackProxy.new(fallback_data, ignore_fallback_overrides: false).for_prefix("baz")
          expect(proxy[:qux]).to eq "42"
        end
      end
    end

    describe "#fetch(key, ttl: nil)" do
      it "must return the value from the data hash" do
        expect(proxy.fetch("foo")).to eq "bar"
      end

      it "must return nil when the val" do
        expect(proxy.fetch("nx-key")).to be_nil
      end
    end

    describe "#for_prefix(key, default_ttl: nil)" do
      it "must return a new instance populated with the sub hash found at the specified key" do
        new_proxy = proxy.for_prefix("baz")
        expect(new_proxy.data).to eq({ qux: 42 }.with_indifferent_access)
      end
    end

    describe "#set_keys" do
      it "merges in a hash" do
        kvs = { foo1: "bar1", foo2: "bar2" }
        proxy.set_keys(kvs)
        expect(proxy.data).to include kvs
      end

      describe "with ignore_fallback_overrides: true" do
        it "does not persist writes to PERSISTED_TREE in Settings" do
          proxy = FallbackProxy.new(fallback_data, FallbackProxy::PERSISTED_TREE, ignore_fallback_overrides: true)
          expect(Setting).not_to receive(:set)
          proxy.set_keys({ foo: "1" })
        end
      end

      describe "with ignore_fallback_overrides: false" do
        before { allow(Setting).to receive(:where).and_return([foo_setting]) }

        it "persists writes to PERSISTED_TREE in Settings" do
          proxy = FallbackProxy.new(fallback_data, FallbackProxy::PERSISTED_TREE, ignore_fallback_overrides: false)
          expect(Setting).to receive(:set).with(foo_key, "2")
          proxy.set_keys({ foo: "2" })
        end

        it "does not persist writes to other trees in Settings" do
          proxy = FallbackProxy.new(fallback_data, ignore_fallback_overrides: false)
          expect(Setting).not_to receive(:set)
          proxy.set_keys({ bzz: "3" })
        end
      end
    end
  end
end
