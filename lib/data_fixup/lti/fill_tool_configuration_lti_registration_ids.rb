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

class DataFixup::Lti::FillToolConfigurationLtiRegistrationIds
  def self.run
    Lti::ToolConfiguration.where.not(developer_key: nil).and(DeveloperKey.where.not(lti_registration: nil)).left_joins(:developer_key, :lti_registration).find_each do |tool_configuration|
      dev_key = tool_configuration.developer_key
      dev_key.lti_registration&.update!(manual_configuration: tool_configuration)
    rescue => e
      Sentry.with_scope do |scope|
        scope.set_tags(developer_key_id: tool_configuration.developer_key.global_id)
        scope.set_context("exception", { name: e.class.name, message: e.message })
        Sentry.capture_message("DataFixup::Lti#fill_tool_configuration_lti_registration_ids", level: :warning)
      end
    end
  end
end
