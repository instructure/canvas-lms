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
    belongs_to :lti_registration, class_name: "Lti::Registration", inverse_of: :manual_configuration, optional: true

    before_validation :normalize_configuration
    before_validation :transform_updated_settings
    before_save :update_privacy_level_from_extensions
    before_save :update_lti_registration
    before_save :set_redirect_uris

    after_update :update_external_tools!, if: :configuration_changed?

    after_commit :update_unified_tool_id, if: :update_unified_tool_id?

    validates :developer_key_id, uniqueness: true, presence: true
    validate :validate_configuration
    validate :validate_placements
    validate :validate_oidc_initiation_urls

    def settings
      return self[:settings] unless transformed?

      Schemas::LtiConfiguration.from_internal_lti_configuration(internal_configuration).with_indifferent_access
    end

    def configuration
      settings
    end

    def transform!
      return if transformed?

      transform_settings
      self.redirect_uris = developer_key.redirect_uris.presence || [target_link_uri]
      save!(validate: false)
    end

    def untransform!
      return unless transformed?

      self[:settings] = settings
      internal_configuration.except(:privacy_level).each_key do |key|
        self[key] = if %i[oidc_initiation_urls custom_fields launch_settings].include?(key)
                      {}
                    elsif %i[placements scopes redirect_uris].include?(key)
                      []
                    else
                      nil
                    end
      end

      @transformed = false
      save!(validate: false)
    end

    def transformed?
      @transformed ||= self[:target_link_uri].present?
    end

    def transform_settings
      internal_config = Schemas::InternalLtiConfiguration.from_lti_configuration(self[:settings]).except(:vendor_extensions)

      allowed_keys = internal_config.keys & internal_configuration.keys
      allowed_keys.each do |key|
        self[key] = internal_config[key]
      end

      self[:settings] = {}
      @transformed = true
    end

    def transform_updated_settings
      return unless transformed?
      return if self[:settings].blank?

      transform_settings
    end

    def self.create_tool_config_and_key!(account, tool_configuration_params, redirect_uris = nil)
      settings = if tool_configuration_params[:settings_url].present? && tool_configuration_params[:settings].blank?
                   retrieve_and_extract_configuration(tool_configuration_params[:settings_url])
                 elsif tool_configuration_params[:settings].present?
                   tool_configuration_params[:settings]&.try(:to_unsafe_hash) || tool_configuration_params[:settings]
                 end

      default_redirect_uris = [settings[:target_link_uri]]
      redirect_uris = redirect_uris.presence || default_redirect_uris

      raise_error(:configuration, "Configuration must be present") if settings.blank?
      transaction do
        dk = DeveloperKey.create!(
          account: (account.site_admin? ? nil : account),
          is_lti_key: true,
          public_jwk_url: settings[:public_jwk_url],
          public_jwk: settings[:public_jwk],
          redirect_uris:,
          scopes: settings[:scopes] || []
        )

        manual_custom_fields = ContextExternalTool.find_custom_fields_from_string(tool_configuration_params[:custom_fields])
        internal_config = Schemas::InternalLtiConfiguration.from_lti_configuration(settings)
        create!(
          developer_key: dk,
          disabled_placements: tool_configuration_params[:disabled_placements],
          privacy_level: tool_configuration_params[:privacy_level] || internal_config[:privacy_level],
          title: internal_config[:title],
          description: internal_config[:description],
          domain: internal_config[:domain],
          tool_id: internal_config[:tool_id],
          target_link_uri: internal_config[:target_link_uri],
          oidc_initiation_url: internal_config[:oidc_initiation_url],
          oidc_initiation_urls: internal_config[:oidc_initiation_urls] || {},
          public_jwk_url: internal_config[:public_jwk_url],
          public_jwk: internal_config[:public_jwk],
          custom_fields: internal_config[:custom_fields]&.merge(manual_custom_fields) || {},
          scopes: internal_config[:scopes],
          redirect_uris:,
          launch_settings: internal_config[:launch_settings] || {},
          placements: internal_config[:placements] || {},
          settings: {}
        )
      end
    end

    def extension_privacy_level
      canvas_extensions["privacy_level"]
    end

    # temporary measure since the actual privacy_level column is not fully backfilled
    # remove with INTEROP-8055
    def privacy_level
      self[:privacy_level] || extension_privacy_level
    end

    def update_privacy_level_from_extensions
      return if transformed?

      ext_privacy_level = extension_privacy_level
      if (self[:privacy_level].nil? || settings_changed?) && self[:privacy_level] != ext_privacy_level && ext_privacy_level.present?
        self[:privacy_level] = ext_privacy_level
      end
    end

    def placements
      return self[:placements] if transformed?
      return [] if configuration.blank?

      configuration["extensions"]&.find { |e| e["platform"] == CANVAS_EXTENSION_LABEL }&.dig("settings", "placements")&.deep_dup || []
    end

    def domain
      return self[:domain] if transformed?
      return "" if configuration.blank?

      configuration["extensions"]&.find { |e| e["platform"] == CANVAS_EXTENSION_LABEL }&.dig("domain") || ""
    end

    # @return [String | nil] A warning message about any disallowed placements
    def verify_placements
      placements_to_verify = placements.filter_map { |p| p["placement"] if Lti::ResourcePlacement::RESTRICTED_PLACEMENTS.include? p["placement"].to_sym }
      return unless placements_to_verify.present? && Account.site_admin.feature_enabled?(:lti_placement_restrictions)

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

    def importable_configuration
      if transformed?
        placements = internal_configuration[:placements].reject { |p| disabled_placements&.include?(p["placement"]) }
        settings = {
          **internal_configuration[:launch_settings],
          placements:
        }
        # legacy: add placements in both array and hash form
        placements.each do |p|
          settings[p["placement"]] = p
        end

        internal_configuration
          .except(:redirect_uris, :launch_settings, :placements)
          .merge({ settings: }, default_tool_settings)
          .with_indifferent_access.compact
      else
        configuration&.merge(canvas_extensions)&.merge(default_tool_settings)
      end
    end

    # @returns InternalLtiConfiguration
    def internal_configuration
      {
        title:,
        description:,
        domain: self[:domain],
        tool_id:,
        privacy_level: self[:privacy_level],
        target_link_uri:,
        oidc_initiation_url:,
        oidc_initiation_urls:,
        public_jwk_url:,
        public_jwk:,
        custom_fields:,
        scopes:,
        redirect_uris:,
        launch_settings:,
        placements: self[:placements],
      }
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

    def update_external_tools!
      developer_key.update_external_tools!
    end

    def update_lti_registration
      self.lti_registration_id = developer_key&.lti_registration_id if developer_key
      true
    end

    def set_redirect_uris
      return unless transformed?
      return if redirect_uris.present?

      self.redirect_uris = [target_link_uri]
    end

    def validate_configuration
      return if configuration.blank?

      if configuration["public_jwk"].blank? && configuration["public_jwk_url"].blank?
        errors.add(:lti_key, "tool configuration must have public jwk or public jwk url")
      end
      if configuration["public_jwk"].present?
        jwk_schema_errors = Schemas::Lti::PublicJwk.simple_validation_first_error(configuration["public_jwk"])
        errors.add(:configuration, jwk_schema_errors) if jwk_schema_errors.present?
      end

      schema_errors = if transformed?
                        Schemas::InternalLtiConfiguration.simple_validation_errors(internal_configuration.compact)
                      else
                        Schemas::LtiConfiguration.simple_validation_errors(configuration.compact)
                      end

      errors.add(:configuration, schema_errors) if schema_errors.present?
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

    def default_tool_settings
      { url: configuration["target_link_uri"], lti_version: "1.3", unified_tool_id: }
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
      self.settings = JSON.parse(configuration) if configuration.is_a? String
      self.settings ||= {}
    rescue JSON::ParserError
      errors.add(:configuration, "Invalid JSON")
      self.settings = {}
      false
    end

    def update_unified_tool_id
      return unless developer_key.root_account.feature_enabled?(:update_unified_tool_id)

      unified_tool_id = LearnPlatform::GlobalApi.get_unified_tool_id(**params_for_unified_tool_id)
      update_column(:unified_tool_id, unified_tool_id) if unified_tool_id
    end
    handle_asynchronously :update_unified_tool_id, priority: Delayed::LOW_PRIORITY

    def params_for_unified_tool_id
      {
        lti_name: settings["title"],
        lti_tool_id: canvas_extensions["tool_id"],
        lti_domain: canvas_extensions["domain"],
        lti_version: "1.3",
        lti_url: settings["target_link_uri"],
      }
    end

    def update_unified_tool_id?
      saved_changes.keys.intersect?(%w[title tool_id domain target_link_uri]) || saved_change_to_settings?
    end

    def configuration_changed?
      saved_changes.keys.intersect?(internal_configuration.keys.map(&:to_s)) || saved_change_to_settings?
    end
  end
end
