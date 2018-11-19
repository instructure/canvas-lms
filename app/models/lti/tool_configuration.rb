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

    belongs_to :developer_key

    before_validation :store_settings_from_url
    before_save :normalize_settings

    validates :developer_key_id, :settings, presence: true
    validates :developer_key_id, uniqueness: true
    validate :valid_tool_settings?, unless: Proc.new { |c| c.developer_key_id.blank? || c.settings.blank? }
    validate :valid_placements

    attr_accessor :settings_url

    def new_external_tool(context)
      tool = ContextExternalTool.new(context: context)
      Importers::ContextExternalToolImporter.import_from_migration(
        importable_settings,
        context,
        nil,
        tool,
        false
      )
      tool.developer_key = developer_key
      tool.custom_fields_string = tool.custom_fields_string + "\n#{custom_fields}"
      tool
    end

    def self.create_tool_and_key!(account, tool_configuration_params)
      self.transaction do
        self.create!(
          developer_key: DeveloperKey.create!(account: account),
          settings: tool_configuration_params[:settings],
          settings_url: tool_configuration_params[:settings_url],
          disabled_placements: tool_configuration_params[:disabled_placements],
          custom_fields: tool_configuration_params[:custom_fields]
        )
      end
    end

    private

    def valid_tool_settings?
      errors.add(:settings, '"public_jwk" must be present') if settings['public_jwk'].blank?
      return if errors[:settings].present?

      tool = new_external_tool(developer_key.owner_account)
      unless tool.valid?
        errors.add(:settings, tool.errors.to_h.map {|k, v| "Tool #{k} #{v}" })
      end
    end

    def valid_placements
      return if disabled_placements.blank?
      invalid = disabled_placements.reject { |p| Lti::ResourcePlacement::PLACEMENTS.include?(p.to_sym) }
      errors.add(:disabled_placements, "Invalid placements: #{invalid.join(', ')}") if invalid.present?
    end

    def importable_settings
      settings&.merge(canvas_extensions)&.merge(settings_map)
    end

    def settings_map
      {url: settings['launch_url']}
    end

    def canvas_extensions
      return {} if settings.blank?
      extension = settings['extensions']&.find { |e| e['platform'] == CANVAS_EXTENSION_LABEL } || {}
      extension['settings'].delete_if { |placement| disabled_placements&.include?(placement.to_s) }
      extension
    end

    def store_settings_from_url
      return if @settings_url.blank?

      response = CC::Importer::BLTIConverter.new.fetch(@settings_url)

      errors.add(:settings_url, 'Content type must be "application/json"') unless response['content-type'].include? 'application/json'
      return if errors[:settings_url].present?

      errors.add(:settings_url, response.message) unless response.is_a? Net::HTTPSuccess
      return if errors[:settings_url].present?

      self.settings = JSON.parse(response.body)
    rescue Timeout::Error
      errors.add(:settings_url, 'Could not retrieve settings, the server response timed out.')
    end

    def normalize_settings
      self.settings = JSON.parse(settings) if settings.is_a? String
    end
  end
end
