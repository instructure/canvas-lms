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

module FeatureFlags
  module Loader
    def self.wrap_hook_method(method_name)
      proc { |*args| FeatureFlags::Hooks.send(method_name, *args) }
    end

    def self.wrap_translate_text(value)
      return -> { "" } if value.empty?

      case value
      when String
        -> { I18n.send(:t, value) }
      when Hash
        wrapper = value.delete(:wrapper)
        keys = value.keys
        raise "invalid i18n settings while translating: #{value}" if keys.size != 1

        if wrapper
          -> { I18n.send(:t, keys[0], value[keys[0]], wrapper: { "*" => wrapper }) }
        else
          -> { I18n.send(:t, keys[0], value[keys[0]]) }
        end
      else
        raise "unable to handle translation: #{value}"
      end
    end

    def self.load_definition(name, definition)
      %i[custom_transition_proc after_state_change_proc visible_on].each do |check|
        definition[check] = wrap_hook_method(definition[check]) if definition[check]
      end
      definition[:type] ||= "feature_option"
      [:display_name, :description].each do |field|
        definition[field] = wrap_translate_text(definition[field])
      end
      definition[:state] = ensure_state_if_boolean(definition[:state]) if definition.key? :state
      definition[:environments]&.each_value do |env|
        env[:state] = ensure_state_if_boolean(env[:state]) if env.key? :state
      end
      Feature.register({ name => definition })
    end

    def self.load_yaml_files
      result = {}
      (Rails.root.glob("config/feature_flags/*.yml") +
        Rails.root.glob("gems/plugins/*/config/feature_flags/*.yml")).sort.each do |path|
        result.merge!(YAML.load_file(path))
      end
      result.each_value(&:deep_symbolize_keys!)
      result
    end

    def self.load_feature_flags
      definitions = load_yaml_files
      definitions.each do |name, definition|
        load_definition(name, definition)
      end
    end

    # the state can be on/off, but those values are parsed as booleans. so to make sure
    # we don't have to put quotes around on/off states in the definitions (which will probably
    # create confusion), just check and transform here if needed
    def self.ensure_state_if_boolean(value)
      if value.is_a?(TrueClass) || value.is_a?(FalseClass)
        return value ? "on" : "off"
      end

      value
    end
  end
end
