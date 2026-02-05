# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# Given an instance of an Lti::ToolConfiguration, coerces commonly invalid
# configuration values to match our schema while still maintaining the behavior
# the configuration would have had with their (invalid) configuration. Maintains
# separation of concerns so Lti::ToolConfiguration doesn't get cluttered with
# cleanup code.
class Lti::ToolConfigurationCleaner
  class << self
    def before_validation(record)
      return unless record.is_a?(Lti::ToolConfiguration)

      clean_dimensions_in_hash(record.launch_settings)
      clean_custom_fields(record.custom_fields)
      infer_default_target_link_uri(record)
      clean_public_jwk(record)
      clean_privacy_level(record)
      clean_placements(record)
    end

    private

    def infer_default_target_link_uri(record)
      return if record.target_link_uri.present? || record.placements.blank? || !record.placements.is_a?(Array)

      default = record.placements.find { it.is_a?(Hash) && it["target_link_uri"].present? }

      record.target_link_uri = default["target_link_uri"] if default.present?
    end

    def clean_public_jwk(record)
      return if record.public_jwk.is_a?(Hash) && record.public_jwk.present?

      # another common misconfiguration is using []. If they're also missing a
      # public_jwk_url, other validations will complain, but this gets them
      # closer to being right.
      record.public_jwk = nil if record.public_jwk.blank?
    end

    def clean_privacy_level(record)
      return if Lti::PrivacyLevelExpander::SUPPORTED_LEVELS.include?(record.privacy_level)

      # This is the default if no value or an invalid value is given to ContextExternalTool.
      # See ContextExternalTool.workflow, where anonymous is the first and initial state.
      record.privacy_level = Lti::Registration::DEFAULT_PRIVACY_LEVEL
    end

    def clean_placements(record)
      return unless record.placements.is_a?(Array)

      record.placements.each do |placement|
        next unless placement.is_a?(Hash)

        clean_boolean_field(placement, "enabled")
        clean_boolean_field(placement, "use_tray")
        clean_window_target(placement)
        clean_dimensions_in_hash(placement)
        clean_default_field(placement)
        clean_visibility_field(placement)
        clean_custom_fields(placement["custom_fields"])
      end
    end

    def clean_visibility_field(placement)
      return unless placement.key?("visibility")

      # Seems to be a somewhat-common misconfiguration value, but we know what they mean.
      if placement["visibility"] == "admin"
        placement["visibility"] = Lti::ToolConfiguration::VISIBLE_TO_ADMINS
      end
    end

    def clean_window_target(placement)
      return unless placement.key?("windowTarget")

      placement.delete("windowTarget") unless placement["windowTarget"] == "_blank"
    end

    def clean_default_field(hash)
      return unless hash.key?("default")
      return if %w[enabled disabled].include?(hash["default"])

      # See external_tool_tab.rb#tabs: We compare
      # the value in "default" directly with "disabled". The only thing
      # that's equal to "disabled" is, well, "disabled", so everything else
      # will be hidden: false, AKA "enabled".
      hash["default"] = "enabled"
    end

    def clean_custom_fields(custom_fields)
      return unless custom_fields.is_a?(Hash)
      return if custom_fields.entries.all? { |k, v| k.is_a?(String) && v.is_a?(String) }

      custom_fields.each do |key, value|
        next if value.is_a?(String) || value.nil?

        # The two most common ways configurations get this wrong is by using an
        # integer or a literal boolean. The LTI spec states that *all* custom
        # variables must be strings and that's how Canvas has been sending it
        # for ages, just make the database match now.
        custom_fields[key] = value.to_s
      end
    end

    def clean_dimensions_in_hash(hash)
      return unless hash.is_a?(Hash)

      %w[selection_height selection_width launch_height launch_width].each do |field|
        next unless hash.key?(field)

        num = Integer(hash[field], exception: false)

        hash[field] = num unless num.nil?
      end
    end

    def clean_boolean_field(hash, field)
      return unless hash.is_a?(Hash) && hash.key?(field)

      converted = Canvas::Plugin.value_to_boolean(hash[field])
      # We have no idea what they want here, just let it fail
      return if converted.nil?

      hash[field] = converted
    end
  end
end
