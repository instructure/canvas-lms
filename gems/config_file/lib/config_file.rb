# frozen_string_literal: true

#
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
#

require "rails"

module ConfigFile
  class << self
    def unstub
      @yaml_cache = {}
      @object_cache = {}
    end
    alias_method :reset_cache, :unstub

    def stub(config_name, value)
      raise "config settings can only be set via config file" unless Rails.env.test?

      existing_cache = @yaml_cache[config_name].dup || {}
      existing_cache[Rails.env] = value
      @yaml_cache[config_name] = deep_freeze_cached_value(existing_cache)
    end

    def load(config_name, with_rails_env = ::Rails.env)
      if @yaml_cache.key?(config_name)
        return @yaml_cache[config_name] unless with_rails_env

        return @yaml_cache[config_name]&.[](with_rails_env)
      end

      path = Rails.root.join("config/#{config_name}.yml")
      if path.file?
        config_string = ERB.new(path.read)
        begin
          config = YAML.safe_load(config_string.result, aliases: true)
        rescue Psych::SyntaxError => e
          raise e, "Error parsing #{path} #{e.message}"
        end
        config = config.with_indifferent_access if config.respond_to?(:with_indifferent_access)
      end
      if config
        @yaml_cache[config_name] = deep_freeze_cached_value(config)
        config = config[with_rails_env] if with_rails_env
      end
      config
    end

    # pass a block; the config will be passed to your block, and the return
    # value will be cached, and returned to you.
    def cache_object(config_name, with_rails_env = ::Rails.env)
      object_cache = @object_cache[config_name] ||= {}
      return object_cache[with_rails_env] if object_cache.key?(with_rails_env)

      config = load(config_name, with_rails_env)
      object_cache[with_rails_env] = (config && yield(config))
    end

    def deep_freeze_cached_value(input)
      return nil if input.nil?
      return deep_freeze_enumerable(input) if needs_deep_freeze?(input)

      input.freeze
      input
    end

    def deep_freeze_enumerable(input)
      return nil if input.nil?

      input.each do |key, value|
        if input.is_a?(Array)
          needs_deep_freeze?(key) ? deep_freeze_enumerable(key) : key.freeze
        end
        needs_deep_freeze?(value) ? deep_freeze_enumerable(value) : value.freeze
      end
      input.freeze
      input
    end

    def needs_deep_freeze?(value)
      value.is_a?(Enumerable) && !value.is_a?(String)
    end
  end
  unstub
end
