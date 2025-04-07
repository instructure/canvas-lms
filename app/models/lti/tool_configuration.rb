# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti
  class ToolConfiguration < ActiveRecord::Base
    self.ignored_columns += ["settings"]

    belongs_to :developer_key
    belongs_to :lti_registration, class_name: "Lti::Registration", inverse_of: :manual_configuration, optional: true

    before_validation :set_redirect_uris
    before_validation :remove_placements_from_launch_settings
    after_update :update_external_tools!, if: :configuration_changed?
    after_commit :update_unified_tool_id, if: :update_unified_tool_id?

    validates :developer_key_id, uniqueness: true, presence: true
    validate :validate_configuration
    validate :validate_placements
    validate :validate_oidc_initiation_urls

    # @return [String | nil] A warning message about any disallowed placements
    def verify_placements
      placements_to_verify = placements.filter_map { |p| p["placement"] if Lti::ResourcePlacement::RESTRICTED_PLACEMENTS.include? p["placement"].to_sym }
      return unless placements_to_verify.present?

      # This is a candidate for a deduplication with the same logic in app/models/context_external_tool.rb#placement_allowed?
      placements_to_verify.each do |placement|
        allowed_domains = Setting.get("#{placement}_allowed_launch_domains", "").split(",").map(&:strip).reject(&:empty?)
        allowed_dev_keys = Setting.get("#{placement}_allowed_dev_keys", "").split(",").map(&:strip).reject(&:empty?)
        next if allowed_domains.include?(domain) || allowed_dev_keys.include?(Shard.global_id_for(developer_key_id).to_s)

        return t(
          "Warning: the %{placement} placement is only allowed for Instructure approved LTI tools. If you believe you have received this message in error, please contact your support team.",
          placement:
        )
      end

      nil
    end

    # @return [String[]] A list of warning messages for deprecated placements
    def placement_warnings
      warnings = []
      if placements.any? { |placement| placement["placement"] == "resource_selection" }
        warnings.push(
          t(
            "Warning: the resource_selection placement is deprecated. Please use assignment_selection and/or link_selection instead."
          )
        )
      end
      may_be_warning = verify_placements
      warnings.push(may_be_warning) unless may_be_warning.nil?
      warnings
    end

    # @returns InternalLtiConfiguration
    def internal_lti_configuration
      {
        title:,
        description:,
        domain:,
        tool_id:,
        privacy_level:,
        target_link_uri:,
        oidc_initiation_url:,
        oidc_initiation_urls:,
        public_jwk_url:,
        public_jwk:,
        custom_fields:,
        scopes:,
        redirect_uris:,
        launch_settings:,
        placements:,
      }
    end

    def self.retrieve_and_extract_configuration(url)
      response = CanvasHttp.get(url)

      raise_error(:configuration_url, 'Content type must be "application/json"') unless response["content-type"].include? "application/json"
      raise_error(:configuration_url, response.message) unless response.is_a? Net::HTTPSuccess

      JSON.parse(response.body).with_indifferent_access
    rescue Timeout::Error
      raise_error(:configuration_url, "Could not retrieve settings, the server response timed out.")
    end

    private

    def self.raise_error(type, message)
      tool_config_obj = new
      tool_config_obj.errors.add(type, message)
      raise ActiveRecord::RecordInvalid, tool_config_obj
    end
    private_class_method :raise_error

    def update_external_tools!
      developer_key.update_external_tools!
    end

    def set_redirect_uris
      return if redirect_uris.present?

      self.redirect_uris = [target_link_uri]
    end

    def remove_placements_from_launch_settings
      launch_settings.delete_if { |p| Lti::ResourcePlacement::PLACEMENTS.include?(p.to_sym) }
    end

    def validate_configuration
      if public_jwk.blank? && public_jwk_url.blank?
        errors.add(:lti_key, "tool configuration must have public jwk or public jwk url")
      end
      if public_jwk.present?
        jwk_schema_errors = Schemas::Lti::PublicJwk.simple_validation_errors(public_jwk)
        jwk_schema_errors&.each { |err| errors.add(:configuration, err) }
      end

      schema_errors = Schemas::InternalLtiConfiguration.simple_validation_errors(internal_lti_configuration.compact)
      schema_errors&.each { |err| errors.add(:configuration, err) }

      false if errors[:configuration].present?
    end

    def validate_placements
      placements.each do |p|
        unless Lti::ResourcePlacement.supported_message_type?(p["placement"], p["message_type"])
          errors.add(:placements, "Placement #{p["placement"]} does not support message type #{p["message_type"]}")
        end
      end

      return if disabled_placements.blank?

      invalid = disabled_placements.reject { |p| Lti::ResourcePlacement::PLACEMENTS.include?(p.to_sym) }
      errors.add(:disabled_placements, "Invalid placements: #{invalid.join(", ")}") if invalid.present?
    end

    def validate_oidc_initiation_urls
      return unless oidc_initiation_urls.is_a?(Hash)

      oidc_initiation_urls.each_value do |url|
        if url.is_a?(String)
          CanvasHttp.validate_url(url, allowed_schemes: nil)
        else
          errors.add(:configuration, "oidc_initiation_urls must be strings")
        end
      end
    rescue CanvasHttp::Error, URI::Error, ArgumentError
      errors.add(:configuration, "oidc_initiation_urls must be valid urls")
    end

    def update_unified_tool_id
      params = {
        lti_name: title,
        lti_tool_id: tool_id,
        lti_domain: domain,
        lti_version: "1.3",
        lti_url: target_link_uri,
      }
      unified_tool_id = LearnPlatform::GlobalApi.get_unified_tool_id(**params)
      update_column(:unified_tool_id, unified_tool_id) if unified_tool_id
    end
    handle_asynchronously :update_unified_tool_id, priority: Delayed::LOW_PRIORITY

    def update_unified_tool_id?
      saved_changes.keys.intersect?(%w[title tool_id domain target_link_uri])
    end

    def configuration_changed?
      saved_changes.keys.intersect?(internal_lti_configuration.keys.map(&:to_s))
    end
  end
end
