# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe PageViews::Configuration do
  before do
    allow(ConfigFile).to receive(:load).with("pv5").and_return("uri" => "http://pv5.instructure.com")
  end

  after do
    RSpec::Mocks.space.proxy_for(ConfigFile).reset
  end

  describe ".configured?" do
    it "returns true when pv5 config is present" do
      expect(PageViews::Configuration.configured?).to be true
    end

    it "returns false when pv5 config is absent" do
      allow(ConfigFile).to receive(:load).with("pv5").and_return(nil)
      expect(PageViews::Configuration.configured?).to be false
    end
  end

  it "raises ConfigurationError when pv5 config is absent" do
    allow(ConfigFile).to receive(:load).with("pv5").and_return(nil)
    expect { PageViews::Configuration.new }.to raise_error(PageViews::Common::ConfigurationError, /not configured/)
  end

  it "loads configuration properly" do
    config = PageViews::Configuration.new
    expect(config.uri).to be_a(URI::HTTP)
    expect(config.uri.to_s).to eq("http://pv5.instructure.com")
  end

  context "with regional configuration" do
    let(:pv5_config) do
      {
        "uri" => "https://api.pv5-iad.inscloudgate.net",
        "regions" => {
          "eu-central-1" => {
            "uri" => "https://api.pv5-fra.inscloudgate.net"
          },
          "us-west-2" => {
            "uri" => "https://api.pv5-pdx.inscloudgate.net"
          }
        }
      }
    end

    before do
      allow(ConfigFile).to receive(:load).with("pv5").and_return(pv5_config)
    end

    it "should select regional URI for eu-central-1 when environment is beta" do
      allow(ENV).to receive(:[]).with("CANVAS_ENVIRONMENT").and_return("beta")

      config = PageViews::Configuration.new(region: "eu-central-1")

      expect(config.uri.to_s).to eq("https://api.pv5-fra.inscloudgate.net")
    end

    it "should select regional URI for us-west-2 when environment is production" do
      allow(ENV).to receive(:[]).with("CANVAS_ENVIRONMENT").and_return("production")

      config = PageViews::Configuration.new(region: "us-west-2")

      expect(config.uri.to_s).to eq("https://api.pv5-pdx.inscloudgate.net")
    end

    it "falls back to default URI when no regional match" do
      config = PageViews::Configuration.new(region: "unknown-region")

      expect(config.uri.to_s).to eq("https://api.pv5-iad.inscloudgate.net")
    end
  end
end
