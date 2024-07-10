# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
class DataFixup::Lti::FixToolConfigurationPrivacyLevel
  def self.run
    # Query for inconsistent privacy_level values (privacy_level and settings->extensions->canvas_platform->privacy_level different)
    Lti::ToolConfiguration.where(
      "NOT (settings->'extensions' @> jsonb_build_array(jsonb_build_object(
      'platform', 'canvas.instructure.com', 'privacy_level', privacy_level)))"
    ).find_each do |tool_configuration|
      if tool_configuration.extension_privacy_level.present?
        tool_configuration.update!(privacy_level: tool_configuration.extension_privacy_level)
      end
    rescue => e
      Sentry.with_scope do |scope|
        scope.set_tags(developer_key_id: tool_configuration.developer_key.global_id, tool_configuration_id: tool_configuration.global_id)
        scope.set_context("exception", { name: e.class.name, message: e.message })
        Sentry.capture_message("DataFixup::Lti#fix_tool_configuration_privacy_level", level: :warning)
      end
    end
  end
end
