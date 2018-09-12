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
    before_save :normalize_settings

    validates :developer_key_id, :settings, presence: true
    validate :valid_tool_settings?, unless: Proc.new { |c| c.developer_key_id.blank? || c.settings.blank? }

    def new_external_tool(context)
      tool = ContextExternalTool.new(context: context)
      Importers::ContextExternalToolImporter.import_from_migration(
        importable_settings,
        context,
        nil,
        tool,
        false
      )
      tool
    end

    private

    def valid_tool_settings?
      tool = new_external_tool(developer_key.owner_account)
      unless tool.valid?
        errors.add(:settings, tool.errors.values.join(' '))
      end
    end

    def importable_settings
      settings&.merge(canvas_extensions)&.merge(settings_map)
    end

    def settings_map
      {url: settings['launch_url']}
    end

    def canvas_extensions
      return {} if settings.blank?
      settings['extensions']&.find { |e| e['platform'] == CANVAS_EXTENSION_LABEL }
    end

    def normalize_settings
      self.settings = JSON.parse(settings) if settings.is_a? String
    end
  end
end