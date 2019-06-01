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
    CANVAS_EXTENSION_LABEL = 'canvas.instructure.com'.freeze
    DEFAULT_PRIVACY_LEVEL = 'anonymous'.freeze

    belongs_to :developer_key

    before_validation :store_configuration_from_url, only: :create
    before_save :normalize_configuration

    validates :developer_key_id, :settings, presence: true
    validates :developer_key_id, uniqueness: true
    validate :valid_configuration?, unless: Proc.new { |c| c.developer_key_id.blank? || c.settings.blank? }
    validate :valid_placements

    attr_accessor :configuration_url, :settings_url

    # settings* was an unfortunate naming choice as there is a settings hash per placement that
    # made it confusing, as well as this being a configuration, not a settings, hash
    alias_attribute :configuration, :settings
    alias_attribute :configuration_url, :settings_url

    def new_external_tool(context)
      tool = ContextExternalTool.new(context: context)
      Importers::ContextExternalToolImporter.import_from_migration(
        importable_configuration,
        context,
        nil,
        tool,
        false
      )
      tool.developer_key = developer_key
      tool.workflow_state = privacy_level || DEFAULT_PRIVACY_LEVEL
      tool.use_1_3 = true
      tool
    end

    def self.create_tool_config_and_key!(account, tool_configuration_params)
      self.transaction do
        dk = DeveloperKey.create!(account: (account.site_admin? ? nil : account))
        settings = tool_configuration_params[:settings]&.try(:to_unsafe_hash) || tool_configuration_params[:settings]

        if settings.present?
          self.create!(
            developer_key: dk,
            configuration: settings.deep_merge(
              'custom_fields' => ContextExternalTool.find_custom_fields_from_string(tool_configuration_params[:custom_fields])
            ),
            disabled_placements: tool_configuration_params[:disabled_placements]
          )
        else
          # Creating config via URL
          t = self.create!(
            developer_key: dk,
            configuration_url: tool_configuration_params[:settings_url],
            disabled_placements: tool_configuration_params[:disabled_placements]
          )
          t.update! configuration: t.configuration.deep_merge(
            'custom_fields' => ContextExternalTool.find_custom_fields_from_string(tool_configuration_params[:custom_fields])
            )
          t
        end
      end
    end

    private

    def valid_configuration?
      errors.add(:configuration, '"public_jwk" must be present') if configuration['public_jwk'].blank?
      schema_errors = Schemas::Lti::ToolConfiguration.simple_validation_errors(configuration)
      errors.add(:configuration, schema_errors) if schema_errors.present?
      return if errors[:configuration].present?

      tool = new_external_tool(developer_key.owner_account)
      unless tool.valid?
        errors.add(:configuration, tool.errors.to_h.map {|k, v| "Tool #{k} #{v}" })
      end
    end

    def valid_placements
      return if disabled_placements.blank?
      invalid = disabled_placements.reject { |p| Lti::ResourcePlacement::PLACEMENTS.include?(p.to_sym) }
      errors.add(:disabled_placements, "Invalid placements: #{invalid.join(', ')}") if invalid.present?
    end

    def importable_configuration
      configuration&.merge(canvas_extensions)&.merge(configuration_to_cet_settings_map)
    end

    def configuration_to_cet_settings_map
      {url: configuration['target_link_uri']}
    end

    def canvas_extensions
      return {} if configuration.blank?
      extension = configuration['extensions']&.find { |e| e['platform'] == CANVAS_EXTENSION_LABEL } || { 'settings' => {} }
      # remove any placements at the root level
      extension['settings'].delete_if { |p| Lti::ResourcePlacement::PLACEMENTS.include?(p.to_sym) }
      # ensure we only have enabled placements being added
      extension['settings'].fetch('placements', []).delete_if { |placement| disabled_placements&.include?(placement['placement']) }
      # readd valid placements to root settings hash
      extension['settings'].fetch('placements', []).each do |p|
        extension['settings'][p['placement']] = p
      end
      extension
    end

    def store_configuration_from_url
      return if configuration_url.blank? || configuration.present?

      response = CC::Importer::BLTIConverter.new.fetch(configuration_url)

      errors.add(:configuration_url, 'Content type must be "application/json"') unless response['content-type'].include? 'application/json'
      return if errors[:configuration_url].present?

      errors.add(:configuration_url, response.message) unless response.is_a? Net::HTTPSuccess
      return if errors[:configuration_url].present?

      self.settings = JSON.parse(response.body)
    rescue Timeout::Error
      errors.add(:configuration_url, 'Could not retrieve settings, the server response timed out.')
    end

    def normalize_configuration
      self.configuration = JSON.parse(configuration) if configuration.is_a? String
    end
  end
end
