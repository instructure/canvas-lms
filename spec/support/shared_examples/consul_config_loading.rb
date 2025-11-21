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
#

# Shared examples for testing config loading from Consul with filesystem fallback
#
# Usage:
#   it_behaves_like "consul config loading", "redis"
#
# Or with custom sample config:
#   it_behaves_like "consul config loading", "redis", sample_config: { "host" => "custom" }
#
RSpec.shared_examples "consul config loading" do |config_name, sample_config: nil|
  let(:default_sample_config) do
    {
      "key" => "value",
      "nested" => { "data" => "test" }
    }
  end

  let(:test_config) { sample_config || default_sample_config }

  describe "loading #{config_name} from Consul" do
    it "loads from Consul when available" do
      stub_consul_config(config_name, test_config)
      config = Canvas.load_config_from_consul(config_name)
      expect(config).to be_present
      expect(config).to be_a(Hash)
    end

    it "falls back to filesystem when Consul is unavailable" do
      stub_consul_with_fallback(config_name, consul_data: nil, file_data: test_config)
      config = Canvas.load_config_from_consul(config_name)
      expect(config).to eq(test_config)
    end

    it "returns nil when neither Consul nor filesystem has the config" do
      stub_consul_unavailable(config_name)
      allow(ConfigFile).to receive(:load).with(config_name, any_args).and_return(nil)
      config = Canvas.load_config_from_consul(config_name)
      expect(config).to be_nil
    end

    it "handles Consul connection errors gracefully" do
      stub_consul_error(config_name, StandardError.new("Connection failed"))
      allow(ConfigFile).to receive(:load).with(config_name, any_args).and_return(test_config)
      config = Canvas.load_config_from_consul(config_name)
      expect(config).to eq(test_config)
    end

    it "returns config with indifferent access" do
      stub_consul_config(config_name, test_config)
      config = Canvas.load_config_from_consul(config_name)
      if config.is_a?(Hash) && config.keys.first.is_a?(String)
        expect(config[config.keys.first.to_sym]).to eq(config[config.keys.first])
      end
    end
  end
end

# Shared examples for testing Consul-only config loading (no filesystem fallback)
#
# Usage:
#   it_behaves_like "consul only config loading", "new_quizzes"
#
RSpec.shared_examples "consul only config loading" do |config_name, sample_config: nil|
  let(:default_sample_config) do
    {
      "key" => "value"
    }
  end

  let(:test_config) { sample_config || default_sample_config }

  describe "loading #{config_name} from Consul only" do
    it "loads from Consul when available" do
      stub_consul_config(config_name, test_config)
      config = Canvas.load_config_from_consul_only(config_name)
      expect(config).to be_present
      expect(config).to eq(test_config)
    end

    it "returns nil when Consul has no config" do
      stub_consul_unavailable(config_name)
      config = Canvas.load_config_from_consul_only(config_name)
      expect(config).to be_nil
    end

    it "does not fall back to filesystem" do
      stub_consul_unavailable(config_name)
      expect(ConfigFile).not_to receive(:load)
      Canvas.load_config_from_consul_only(config_name)
    end
  end
end
