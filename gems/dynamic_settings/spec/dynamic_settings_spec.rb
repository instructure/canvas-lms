# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe DynamicSettings do
  before do
    @cached_config = DynamicSettings.config
    @cached_fallback_data = DynamicSettings.fallback_data
    fake_conf_location = Pathname.new(File.join(File.dirname(__FILE__), "fixtures"))
    allow(Rails).to receive(:root).and_return(fake_conf_location)
  end

  after do
    begin
      DynamicSettings.config = @cached_config
    rescue Diplomat::KeyNotFound
      # don't fail the test if there is no consul running
      DynamicSettings.logger.debug("failed config reset because no consul")
    end
    DynamicSettings.fallback_data = @cached_fallback_data
    DynamicSettings.reset_cache!
  end

  let(:parent_key) { "rich-content-service" }
  let(:kv_client) { DynamicSettings.kv_client }
  let(:valid_config) do
    {
      "host" => "consul",
      "port" => 8500,
      "ssl" => true,
      "acl_token" => "some-long-string",
      "environment" => "rspec",
    }
  end

  describe ".config=" do
    it "configures diplomat when config is set" do
      DynamicSettings.config = valid_config
      expect(Diplomat.configuration.url.to_s).to eq("https://consul:8500")
    end

    it "must pass through timeout settings to the underlying library" do
      DynamicSettings.config = valid_config.merge({
                                                    "connect_timeout" => 1,
                                                    "timeout" => 2
                                                  })

      options = Diplomat.configuration.options
      expect(options[:request][:open_timeout]).to eq 1
      expect(options[:request][:timeout]).to eq 2
    end

    it "must capture the environment name when supplied" do
      DynamicSettings.config = valid_config.merge({
                                                    "environment" => "foobar"
                                                  })

      expect(DynamicSettings.environment).to eq "foobar"
    end
  end

  describe ".find" do
    context "when consul is configured" do
      before do
        DynamicSettings.config = valid_config
      end

      it "must return a PrefixProxy when consul is configured" do
        proxy = DynamicSettings.find("foo")
        expect(proxy).to be_a(DynamicSettings::PrefixProxy)
      end
    end

    context "when consul is not configured" do
      let(:data) do
        {
          config: {
            canvas: { foo: { bar: "baz" } },
            frobozz: { some: { thing: "magic" } }
          },
          private: {
            canvas: { zab: { rab: "oof" } }
          }
        }
      end

      before do
        DynamicSettings.config = nil
        DynamicSettings.fallback_data = data
      end

      after do
        DynamicSettings.fallback_data = nil
      end

      it "must return an empty FallbackProxy when fallback data is also unconfigured" do
        DynamicSettings.fallback_data = nil
        expect(DynamicSettings.find("foo")).to be_a(DynamicSettings::FallbackProxy)
        expect(DynamicSettings.find("foo")["bar"]).to be_nil
      end

      it "must return a FallbackProxy with configured fallback data" do
        proxy = DynamicSettings.find("foo", tree: "config", service: "canvas")
        expect(proxy).to be_a(DynamicSettings::FallbackProxy)
        expect(proxy[:bar]).to eq "baz"
      end

      it "must default the the config tree" do
        proxy = DynamicSettings.find("foo", service: "canvas")
        expect(proxy["bar"]).to eq "baz"
      end

      it "must handle an alternate tree" do
        proxy = DynamicSettings.find("zab", tree: "private", service: "canvas")
        expect(proxy["rab"]).to eq "oof"
      end

      it "must default to the canvas service" do
        proxy = DynamicSettings.find("foo", tree: "config")
        expect(proxy["bar"]).to eq "baz"
      end

      it "must accept an alternate service" do
        proxy = DynamicSettings.find("some", tree: "config", service: "frobozz")
        expect(proxy["thing"]).to eq "magic"
      end

      it "must ignore a nil prefix" do
        proxy = DynamicSettings.find(tree: "config", service: "canvas")
        expect(proxy.for_prefix("foo")["bar"]).to eq "baz"
      end
    end
  end
end
