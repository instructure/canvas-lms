# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require 'yaml'

module FeatureFlags
  module Loader
    def self.wrap_hook_method(method_name)
      proc { |*args| FeatureFlags::Hooks.send(method_name, *args) }
    end

    def self.wrap_translate_text(value)
      return -> { "" } if value.empty?
      if value.is_a?(String)
        return -> { I18n.send(:t, value) }
      elsif value.is_a?(Hash)
        wrapper = value.delete(:wrapper)
        keys = value.keys
        raise "invalid i18n settings while translating: #{value}" if keys.size != 1
        if wrapper
          return -> { I18n.send(:t, keys[0], value[keys[0]], wrapper: { '*' => wrapper }) }
        else
          return -> { I18n.send(:t, keys[0], value[keys[0]]) }
        end
      else
        raise "unable to handle translation: #{value}"
      end
    end

    def self.load_definition(name, definition)
      [:custom_transition_proc, :after_state_change_proc, :visible_on].each do |check|
        definition[check] = wrap_hook_method(definition[check]) if definition[check]
      end
      [:display_name, :description].each do |field|
        definition[field] = wrap_translate_text(definition[field])
      end
      definition[:state] = ensure_state_if_boolean(definition[:state]) if definition.key? :state
      definition[:environments]&.each do |_env_name, env|
        env[:state] = ensure_state_if_boolean(env[:state]) if env.key? :state
      end
      Feature.register({ name => definition })
    end

    def self.load_yaml_files
      result = {}
      Dir.glob(Rails.root.join('config', 'feature_flags', "*.yml")).sort!.each do |path|
        result.merge!(YAML.load_file(path))
      end
      result.each do |_name, definition|
        definition.deep_symbolize_keys!
      end
      result
    end

    def self.load_feature_flags
      definitions = self.load_yaml_files
      definitions.each do |name, definition|
        self.load_definition(name, definition)
      end
    end

    # the state can be on/off, but those values are parsed as booleans. so to make sure
    # we don't have to put quotes around on/off states in the definitions (which will probably
    # create confusion), just check and transform here if needed
    def self.ensure_state_if_boolean(value)
      if value.is_a?(TrueClass) || value.is_a?(FalseClass)
        return value ? "on" : "off"
      end
      return value
    end
  end
end
