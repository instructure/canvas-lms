# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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

describe SentryExtensions::Settings do
  # Stub Canvas methods globally so they're available in all tests
  before do
    allow(Canvas).to receive(:region).and_return(nil) unless RSpec.current_example.metadata[:skip_canvas_stubs]
    allow(Canvas).to receive(:availability_zone).and_return(nil) unless RSpec.current_example.metadata[:skip_canvas_stubs]
  end

  describe ".settings" do
    context "when the config is available from Consul" do
      before do
        stub_consul_config("sentry", {
                             dsn: "consul-dsn",
                             frontend_dsn: "consul-frontend-dsn"
                           })
        allow(Canvas).to receive_messages(region_code: "iad", region: "us-east-1", availability_zone: "us-east-1a")
      end

      it "returns settings from Consul" do
        settings = described_class.settings

        expect(settings[:dsn]).to eq("consul-dsn")
        expect(settings[:frontend_dsn]).to eq("consul-frontend-dsn")
      end
    end

    context "when Consul is unavailable" do
      before do
        stub_consul_with_fallback("sentry",
                                  consul_data: nil,
                                  file_data: { dsn: "file-dsn", frontend_dsn: "file-frontend-dsn" })
        allow(Canvas).to receive_messages(region_code: "iad", region: "us-east-1", availability_zone: "us-east-1a")
      end

      it "falls back to filesystem config" do
        settings = described_class.settings

        expect(settings[:dsn]).to eq("file-dsn")
        expect(settings[:frontend_dsn]).to eq("file-frontend-dsn")
      end
    end

    context "when the config file is missing" do
      before do
        stub_consul_unavailable("sentry")
        allow(ConfigFile).to receive(:load).with("sentry", Rails.env).and_return(nil)
      end

      it "returns an empty hash" do
        settings = described_class.settings

        expect(settings).to eq({})
      end
    end

    context "when DSN contains {region} placeholder" do
      before do
        stub_consul_config("sentry", {
                             dsn: "https://abc@relay-{region}.sentry.insops.net/1",
                             frontend_dsn: "https://xyz@relay-{region}.sentry.insops.net/2",
                             org_slug: "instructure",
                             base_url: "https://sentry.insops.net"
                           })
        allow(Canvas).to receive_messages(region_code: "pdx", region: "us-west-2", availability_zone: "us-west-2a")
      end

      it "interpolates region into DSN URLs" do
        settings = described_class.settings

        expect(settings[:dsn]).to eq("https://abc@relay-pdx.sentry.insops.net/1")
        expect(settings[:frontend_dsn]).to eq("https://xyz@relay-pdx.sentry.insops.net/2")
      end

      it "includes other config fields" do
        settings = described_class.settings

        expect(settings[:org_slug]).to eq("instructure")
        expect(settings[:base_url]).to eq("https://sentry.insops.net")
      end

      it "generates runtime tags from Canvas methods" do
        settings = described_class.settings

        expect(settings[:tags]).to eq({
                                        "aws_region" => "us-west-2",
                                        "availability_zone" => "us-west-2a"
                                      })
      end
    end

    context "when DSN does not contain {region} placeholder (backwards compatibility)" do
      before do
        stub_consul_config("sentry", {
                             dsn: "https://abc@relay-iad.sentry.insops.net/1",
                             frontend_dsn: "https://xyz@relay-iad.sentry.insops.net/2"
                           })
        allow(Canvas).to receive_messages(region_code: "pdx", region: "us-west-2", availability_zone: "us-west-2a")
      end

      it "returns DSN URLs unchanged" do
        settings = described_class.settings

        expect(settings[:dsn]).to eq("https://abc@relay-iad.sentry.insops.net/1")
        expect(settings[:frontend_dsn]).to eq("https://xyz@relay-iad.sentry.insops.net/2")
      end
    end

    context "when Canvas.region_code returns nil" do
      before do
        stub_consul_config("sentry", {
                             dsn: "https://abc@relay-{region}.sentry.insops.net/1",
                             frontend_dsn: "https://xyz@relay-{region}.sentry.insops.net/2"
                           })
        allow(Canvas).to receive_messages(region_code: nil, region: "us-west-2", availability_zone: "us-west-2a")
      end

      it "skips region interpolation and uses DSNs as-is" do
        settings = described_class.settings

        expect(settings[:dsn]).to eq("https://abc@relay-{region}.sentry.insops.net/1")
        expect(settings[:frontend_dsn]).to eq("https://xyz@relay-{region}.sentry.insops.net/2")
      end
    end

    context "when some tag methods return nil" do
      before do
        stub_consul_config("sentry", {
                             dsn: "https://abc@relay-iad.sentry.insops.net/1"
                           })
        allow(Canvas).to receive_messages(region_code: "iad", region: nil, availability_zone: "us-west-2a")
      end

      it "only includes non-nil tags" do
        settings = described_class.settings

        # aws_region is stubbed to return nil, so it should be excluded
        expect(settings[:tags]).to eq({
                                        "availability_zone" => "us-west-2a"
                                      })
      end
    end
  end

  describe ".get" do
    context "when the key exists in the config file" do
      before do
        stub_consul_config("sentry", { key: "config-value" })
        allow(Canvas).to receive_messages(region_code: "iad", region: "us-east-1", availability_zone: "us-east-1a")
        Setting.set("key", "db-value")
      end

      after do
        Setting.remove("key")
      end

      it "returns the value from the config file" do
        expect(described_class.get("key", "default")).to eq("config-value")
      end
    end

    context "when the setting exists in the db" do
      before do
        stub_consul_unavailable("sentry")
        # Allow ConfigFile.load to be called for any config
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("sentry", Rails.env).and_return(nil)
        Setting.set("key", "db-value")
      end

      after do
        Setting.remove("key")
      end

      it "returns the value from the db" do
        expect(described_class.get("key", "default")).to eq("db-value")
      end
    end

    context "when the setting doesn't exist" do
      before do
        stub_consul_unavailable("sentry")
        # Allow ConfigFile.load to be called for any config
        allow(ConfigFile).to receive(:load).and_call_original
        allow(ConfigFile).to receive(:load).with("sentry", Rails.env).and_return(nil)
      end

      it "returns the provided default value" do
        expect(described_class.get("key", "default")).to eq("default")
      end

      it "returns nil if no default is provided" do
        expect(described_class.get("key")).to be_nil
      end
    end
  end

  describe ".reset_settings" do
    before do
      allow(Canvas).to receive_messages(region_code: "iad", region: "us-east-1", availability_zone: "us-east-1a")
    end

    it "resets loaded settings" do
      stub_consul_config("sentry", { dsn: "first-value" })
      expect(described_class.settings[:dsn]).to eq("first-value")

      stub_consul_config("sentry", { dsn: "second-value" })

      expect(described_class.settings[:dsn]).to eq("first-value")
      described_class.reset_settings
      expect(described_class.settings[:dsn]).to eq("second-value")
    end
  end
end
