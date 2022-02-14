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
  describe ".settings" do
    context "when the config file is present" do
      before do
        ConfigFile.stub("sentry", {
                          development: { dsn: "your-sandbox-dsn-here", frontend_dsn: "your-sandbox-frontend-dsn-here" },
                          production: { dsn: "your-real-dsn-here", frontend_dsn: "your-real-frontend-dsn-here" }
                        })
      end

      after do
        ConfigFile.unstub
        described_class.reset_settings
      end

      it "returns settings from the config" do
        settings = described_class.settings

        expect(settings.keys.map(&:to_sym)).to eq(%i[development production])
        expect(settings[:production][:dsn]).to eq("your-real-dsn-here")
      end
    end

    context "when the config file is missing" do
      it "returns an empty hash" do
        settings = described_class.settings

        expect(settings).to eq({})
      end
    end
  end

  describe ".get" do
    context "when the key exists in the config file" do
      before do
        ConfigFile.stub("sentry", { key: "config-value" })
        Setting.set("key", "db-value")
      end

      after do
        ConfigFile.unstub
        described_class.reset_settings
        Setting.remove("key")
      end

      it "returns the value from the config file" do
        expect(described_class.get("key", "default")).to eq("config-value")
      end
    end

    context "when the setting exists in the db" do
      before do
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
      ConfigFile.stub("sentry", "first-value")
    end

    after do
      ConfigFile.unstub
      described_class.reset_settings
    end

    it "resets loaded settings" do
      expect(described_class.settings).to eq("first-value")

      ConfigFile.stub("sentry", "second-value")

      expect(described_class.settings).to eq("first-value")
      described_class.reset_settings
      expect(described_class.settings).to eq("second-value")
    end
  end
end
