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
    CANVAS_EXTENSION_LABEL = "canvas.instructure.com"
    DEFAULT_PRIVACY_LEVEL = "anonymous"

    belongs_to :developer_key

    before_save :normalize_configuration
    before_save :update_privacy_level_from_extensions

    after_update :update_external_tools!, if: :update_external_tools?

    validates :developer_key_id, :settings, presence: true
    validates :developer_key_id, uniqueness: true
    validate :validate_configuration, unless: proc { |c| c.developer_key_id.blank? || c.settings.blank? }
    validate :validate_placements
    validate :validate_oidc_initiation_urls

    attr_accessor :settings_url

    # settings* was an unfortunate naming choice as there is a settings hash per placement that
    # made it confusing, as well as this being a configuration, not a settings, hash
    alias_attribute :configuration, :settings
    alias_method :configuration_url, :settings_url
    alias_method :configuration_url=, :settings_url=

    def new_external_tool(context, existing_tool: nil)
      # disabled tools should stay disabled while getting updated
      # deleted tools are never updated during a dev key update so can be safely ignored
      tool_is_disabled = existing_tool&.workflow_state == ContextExternalTool::DISABLED_STATE

      tool = existing_tool || ContextExternalTool.new(context:)
      Importers::ContextExternalToolImporter.import_from_migration(
        importable_configuration,
        context,
        nil,
        tool,
        false
      )
      tool.developer_key = developer_key
      tool.workflow_state = (tool_is_disabled && ContextExternalTool::DISABLED_STATE) || privacy_level || DEFAULT_PRIVACY_LEVEL
      tool
    end

    def self.create_tool_config_and_key!(account, tool_configuration_params)
      settings = if tool_configuration_params[:settings_url].present? && tool_configuration_params[:settings].blank?
                   retrieve_and_extract_configuration(tool_configuration_params[:settings_url])
                 elsif tool_configuration_params[:settings].present?
                   tool_configuration_params[:settings]&.try(:to_unsafe_hash) || tool_configuration_params[:settings]
                 end

      # try to recover the target_link_url from the tool configuration and use
      # it into developer_key.redirect_uris
      redirect_uris = settings[:target_link_uri]

      raise_error(:configuration, "Configuration must be present") if settings.blank?
      transaction do
        dk = DeveloperKey.create!(
          account: (account.site_admin? ? nil : account),
          is_lti_key: true,
          public_jwk_url: settings[:public_jwk_url],
          public_jwk: settings[:public_jwk],
          redirect_uris: redirect_uris || [],
          scopes: settings[:scopes] || []
        )
        create!(
          developer_key: dk,
          configuration: settings.deep_merge(
            "custom_fields" => ContextExternalTool.find_custom_fields_from_string(tool_configuration_params[:custom_fields])
          ),
          configuration_url: tool_configuration_params[:settings_url],
          disabled_placements: tool_configuration_params[:disabled_placements],
          privacy_level: tool_configuration_params[:privacy_level]
        )
      end
    end

    # temporary measure since the actual privacy_level column is not fully backfilled
    # remove with INTEROP-8055
    def privacy_level
      self[:privacy_level] || canvas_extensions["privacy_level"]
    end

    def update_privacy_level_from_extensions
      ext_privacy_level = canvas_extensions["privacy_level"]
      if settings_changed? && self[:privacy_level] != ext_privacy_level && ext_privacy_level.present?
        self[:privacy_level] = ext_privacy_level
      end
    end

    def placements
      return [] if configuration.blank?

      configuration["extensions"]&.find { |e| e["platform"] == CANVAS_EXTENSION_LABEL }&.dig("settings", "placements")&.deep_dup || []
    end

    def domain
      return [] if configuration.blank?

      configuration["extensions"]&.find { |e| e["platform"] == CANVAS_EXTENSION_LABEL }&.dig("domain") || ""
    end

    # @return [String | nil] A warning message about any disallowed placements
    def verify_placements
      return unless placements.any? { |p| p["placement"] == "submission_type_selection" }
      return unless Account.site_admin.feature_enabled?(:lti_placement_restrictions)

      # This is a candidate for a deduplication with the same logic in app/models/context_external_tool.rb#placement_allowed?
      allowed_domains = Setting.get("submission_type_selection_allowed_launch_domains", "").split(",").map(&:strip).reject(&:empty?)
      allowed_dev_keys = Setting.get("submission_type_selection_allowed_dev_keys", "").split(",").map(&:strip).reject(&:empty?)
      return if allowed_domains.include?(domain) || allowed_dev_keys.include?(Shard.global_id_for(developer_key_id).to_s)

      t("Warning: the submission_type_selection placement is only allowed for Instructure approved LTI tools. If you believe you have received this message in error, please contact your support team.")
    end

    private

    def self.retrieve_and_extract_configuration(url)
      response = CanvasHttp.get(url)

      raise_error(:configuration_url, 'Content type must be "application/json"') unless response["content-type"].include? "application/json"
      raise_error(:configuration_url, response.message) unless response.is_a? Net::HTTPSuccess

      JSON.parse(response.body).with_indifferent_access
    rescue Timeout::Error
      raise_error(:configuration_url, "Could not retrieve settings, the server response timed out.")
    end
    private_class_method :retrieve_and_extract_configuration

    def self.raise_error(type, message)
      tool_config_obj = new
      tool_config_obj.errors.add(type, message)
      raise ActiveRecord::RecordInvalid, tool_config_obj
    end
    private_class_method :raise_error

    def update_external_tools?
      saved_change_to_settings?
    end

    def update_external_tools!
      developer_key.update_external_tools!
    end

    def validate_configuration
      if configuration["public_jwk"].blank? && configuration["public_jwk_url"].blank?
        errors.add(:lti_key, "tool configuration must have public jwk or public jwk url")
      end
      if configuration["public_jwk"].present?
        jwk_schema_errors = Schemas::Lti::PublicJwk.simple_validation_errors(configuration["public_jwk"])
        errors.add(:configuration, jwk_schema_errors) if jwk_schema_errors.present?
      end
      schema_errors = Schemas::Lti::ToolConfiguration.simple_validation_errors(configuration.compact)
      errors.add(:configuration, schema_errors) if schema_errors.present?
      return false if errors[:configuration].present?

      tool = new_external_tool(developer_key.owner_account)
      unless tool.valid?
        errors.add(:configuration, tool.errors.to_h.map { |k, v| "Tool #{k} #{v}" })
      end
    end

    def validate_placements
      return if disabled_placements.blank?

      invalid = disabled_placements.reject { |p| Lti::ResourcePlacement::PLACEMENTS.include?(p.to_sym) }
      errors.add(:disabled_placements, "Invalid placements: #{invalid.join(", ")}") if invalid.present?
    end

    def validate_oidc_initiation_urls
      urls_hash = configuration&.dig("oidc_initiation_urls")
      return unless urls_hash.is_a?(Hash)

      urls_hash.each_value do |url|
        if url.is_a?(String)
          CanvasHttp.validate_url(url, allowed_schemes: nil)
        else
          errors.add(:configuration, "oidc_initiation_urls must be strings")
        end
      end
    rescue CanvasHttp::Error, URI::Error, ArgumentError
      errors.add(:configuration, "oidc_initiation_urls must be valid urls")
    end

    def importable_configuration
      configuration&.merge(canvas_extensions)&.merge(configuration_to_cet_settings_map)
    end

    def configuration_to_cet_settings_map
      { url: configuration["target_link_uri"], lti_version: "1.3" }
    end

    def canvas_extensions
      return {} if configuration.blank?

      extension = configuration["extensions"]&.find { |e| e["platform"] == CANVAS_EXTENSION_LABEL }&.deep_dup || { "settings" => {} }
      # remove any placements at the root level
      extension["settings"].delete_if { |p| Lti::ResourcePlacement::PLACEMENTS.include?(p.to_sym) }
      # ensure we only have enabled placements being added
      extension["settings"].fetch("placements", []).delete_if { |placement| disabled_placements&.include?(placement["placement"]) }
      # read valid placements to root settings hash
      extension["settings"].fetch("placements", []).each do |p|
        extension["settings"][p["placement"]] = p
      end
      extension
    end

    def normalize_configuration
      self.configuration = JSON.parse(configuration) if configuration.is_a? String
    end
  end
end
