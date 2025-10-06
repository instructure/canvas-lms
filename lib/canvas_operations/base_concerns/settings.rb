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

require_relative "../errors"

module CanvasOperations
  module BaseConcerns
    # Configurable settings for CanvasOperations::BaseOperation and its subclasses.
    #
    # Subclasses can set configurable settings using the `setting` class method:
    # ```ruby
    # setting :sleep_time, default: 10, type_cast: :to_i
    # ```
    #
    # `type_cast` can be a Symbol representing a method to call on the raw
    # String value (e.g. `:to_i`, `:to_f`, `:to_s`), or a Proc/lambda that
    # takes the raw String value and returns the casted value.
    #
    # Example type_cast with a Proc:
    # ```ruby
    # setting :do_sleep, default: false, type_cast: ->(string_value) { ActiveModel::Type::Boolean.new.cast(string_value) }
    # ```
    #
    # Settings are currently backed by the Canvas `Setting` model, which is un-sharded.
    # Settings, however, are namespaced by the operation name and cluster, so can be overridden
    # per cluster.
    #
    # Example `Setting` name for an operation named `MyOperation`, setting `sleep_time`, on cluster 2:
    # ```
    # clusters/cluster2/my_operation/sleep_time
    # ```
    #
    # Declaring a setting will create the following methods:
    # - Class method to get the setting value, with an optional `cluster:` keyword argument. If
    #   cluster is omitted, the current shard's cluster is used.
    #     example: `MyOperation.sleep_time` or `MyOperation.sleep_time(cluster: 2)`
    # - Class method to set the setting value for the current shard's cluster
    #     example: `MyOperation.sleep_time = 5`
    # - Class method to set the setting value for a specific cluster
    #     example: `MyOperation.set_sleep_time_for_cluster(5, cluster: 2)`
    # - Protected instance method to get the setting value for the current shard's cluster
    #     example (from the Operation instance context): `sleep_time`
    #
    # settings should be _set_ fairly sparingly. They are best suited for configuration where the
    # default holds the the majority of the time, and overrides are infrequent.
    module Settings
      # Setting values are always Strings
      SETTINGS_TYPE_INSTANCE = ""

      def setting_for(name, default:, cluster:)
        Canvas::Reloader.reload

        settings_key = settings_key(name, cluster:)
        value = Setting.get(settings_key, default)
        log_message("Fetched setting #{settings_key} with value `#{value.inspect}` before type casting", level: :debug)

        value
      end

      def modify_setting_for(name, value, cluster:)
        was_success = Setting.set(settings_key(name, cluster:), value)
        log_message("Modified setting #{settings_key(name, cluster:)} to value `#{value.inspect}` successfully? #{was_success}")

        was_success
      end

      def setting(setting_name, default:, type_cast: :to_s)
        raise ArgumentError, "setting_name cannot be nil" if setting_name.nil?
        raise ArgumentError, "setting_name must be a symbol or string" unless setting_name.is_a?(Symbol) || setting_name.is_a?(String)

        validate_type_cast!(type_cast, setting_name)

        # Method to get the Setting value and apply type casting
        #
        # If no cluster is provided, the current shard's cluster.
        define_singleton_method(setting_name) do |cluster: nil|
          cluster ||= Shard.current.database_server.id

          raw_value = setting_for(setting_name, default:, cluster:)

          case type_cast
          when Symbol
            raw_value.public_send(type_cast)
          when Proc
            type_cast.call(raw_value)
          end
        end

        # Method to set the Setting value
        #
        # Assumes the current shard's cluster
        define_singleton_method("#{setting_name}=") do |value|
          public_send("set_#{setting_name}_for_cluster", value, cluster: Shard.current.database_server.id)
        end

        # Method to set the Setting value for a specific cluster
        define_singleton_method("set_#{setting_name}_for_cluster") do |value, cluster:|
          modify_setting_for(setting_name, value, cluster:)
        end

        # Convenience protected instance methods for accessing settings
        #
        # Always returns the setting for the operation's current shard's cluster.
        define_method(setting_name) do
          self.class.send(setting_name, cluster:)
        end
        protected setting_name
      end

      def validate_type_cast!(type_cast, setting_name)
        case type_cast
        when Symbol
          # Setting values are always Strings, so ensure the type_cast method exists on String
          unless SETTINGS_TYPE_INSTANCE.respond_to?(type_cast)
            raise Errors::InvalidTypeCast,
                  "Unsupported type_cast `#{type_cast}` for setting `#{setting_name}`. #{SETTINGS_TYPE_INSTANCE.class} does not respond to `#{type_cast}`."
          end
        when Proc
          unless type_cast.arity == 1
            raise Errors::InvalidTypeCast, "type_cast Proc must take exactly one argument for setting `#{setting_name}`"
          end
        else
          raise Errors::InvalidTypeCast, "Unsupported type_cast `#{type_cast}` for setting `#{setting_name}`"
        end
      end

      def settings_key(setting_name, cluster:)
        "clusters/#{cluster}/#{operation_name}/#{setting_name}"
      end
    end
  end
end
