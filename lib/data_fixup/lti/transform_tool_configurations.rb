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

module DataFixup::Lti::TransformToolConfigurations
  def self.run
    Lti::ToolConfiguration.find_each do |tc|
      tc.transform!
    rescue => e
      Sentry.with_scope do |scope|
        scope.set_tags(tool_configuration_id: tc.global_id)
        scope.set_context("exception", { name: e.class.name, message: e.message })
        Sentry.capture_message("DataFixup::Lti#transform_tool_configurations", level: :warning)
      end
    end
  end
end
