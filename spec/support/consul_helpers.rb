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

module ConsulHelpers
  # Stub DynamicSettings to return specific config data
  #
  # @param config_name [String] Config file name (e.g., "redis")
  # @param data [Hash] Configuration data to return
  # @param tree [Symbol] Tree to use (:private, :config, :store)
  # @param cluster [String, nil] Optional cluster parameter
  #
  # @example
  #   stub_consul_config("redis", { "host" => "localhost", "port" => 6379 })
  #
  # @example With cluster
  #   stub_consul_config("cache_store", { "cache_store" => "redis" }, cluster: "cluster21")
  #
  def stub_consul_config(config_name, data, tree: :private, cluster: nil)
    proxy = instance_double(DynamicSettings::PrefixProxy)
    # Allow DynamicSettings.find with any arguments (for other code)
    allow(DynamicSettings).to receive(:find).and_call_original
    # Then stub the specific tree we care about
    if cluster
      allow(DynamicSettings).to receive(:find).with(hash_including(tree:, cluster:)).and_return(proxy)
    else
      allow(DynamicSettings).to receive(:find).with(hash_including(tree:)).and_return(proxy)
    end
    # Allow other configs to return nil so they don't interfere (must come first)
    allow(proxy).to receive(:[]).and_return(nil)
    # Allow the specific config we're testing (must come second to override)
    allow(proxy).to receive(:[]).with("#{config_name}.yml", any_args).and_return(YAML.dump(data))
    proxy
  end

  # Stub Consul to be unavailable (returns nil/failsafe)
  #
  # @param config_name [String] Config file name
  # @param failsafe_value [Object] Value to return as failsafe (default: nil)
  # @param tree [Symbol] Tree to use (:private, :config, :store)
  #
  # @example Basic usage
  #   stub_consul_unavailable("redis")
  #
  # @example With failsafe value
  #   stub_consul_unavailable("redis", failsafe_value: "{}")
  #
  def stub_consul_unavailable(config_name, failsafe_value: nil, tree: :private)
    proxy = instance_double(DynamicSettings::PrefixProxy)
    # Allow DynamicSettings.find with any arguments (for other code)
    allow(DynamicSettings).to receive(:find).and_call_original
    # Then stub the specific tree we care about
    allow(DynamicSettings).to receive(:find).with(hash_including(tree:)).and_return(proxy)
    # Allow other configs to return nil so they don't interfere (must come first)
    allow(proxy).to receive(:[]).and_return(nil)
    # Allow the specific config we're testing (must come second to override)
    allow(proxy).to receive(:[]).with("#{config_name}.yml", any_args).and_return(failsafe_value)
    proxy
  end

  # Stub Consul with filesystem fallback
  #
  # @param config_name [String] Config file name
  # @param consul_data [Hash, nil] Data from Consul (nil simulates unavailable)
  # @param file_data [Hash] Data from filesystem fallback
  # @param tree [Symbol] Tree to use (:private, :config, :store)
  # @param environment [String, Boolean] Rails environment (default: Rails.env)
  #
  # @example
  #   stub_consul_with_fallback("redis",
  #                            consul_data: nil,
  #                            file_data: { "host" => "fallback" })
  #
  def stub_consul_with_fallback(config_name, consul_data: nil, file_data: {}, tree: :private, environment: Rails.env)
    if consul_data.nil?
      stub_consul_unavailable(config_name, tree:)
      allow(ConfigFile).to receive(:load).with(config_name, environment).and_return(file_data)
    else
      stub_consul_config(config_name, consul_data, tree:)
    end
  end

  # Stub Consul to raise an error
  #
  # @param config_name [String] Config file name
  # @param error [StandardError] Error to raise (default: StandardError)
  # @param tree [Symbol] Tree to use (:private, :config, :store)
  #
  # @example
  #   stub_consul_error("redis", StandardError.new("Connection failed"))
  #
  def stub_consul_error(config_name, error = StandardError.new("Consul error"), tree: :private)
    proxy = instance_double(DynamicSettings::PrefixProxy)
    # Allow DynamicSettings.find with any arguments (for other code)
    allow(DynamicSettings).to receive(:find).and_call_original
    # Then stub the specific tree we care about
    allow(DynamicSettings).to receive(:find).with(hash_including(tree:)).and_return(proxy)
    # Allow other configs to return nil so they don't interfere (must come first)
    allow(proxy).to receive(:[]).and_return(nil)
    # Allow the specific config we're testing (must come second to override)
    allow(proxy).to receive(:[]).with("#{config_name}.yml", any_args).and_raise(error)
    proxy
  end
end

RSpec.configure do |config|
  config.include ConsulHelpers
end
