# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
#

# Lti::AssetProcessor model, accessible through an Assignment
module Types
  class LtiAssetProcessorType < ApplicationObjectType
    implements Interfaces::LegacyIDInterface

    field :external_tool, Types::ExternalToolType, null: true
    def external_tool
      load_association(:context_external_tool)
    end

    field :text, String, null: true
    field :title, String, null: true

    field :icon_or_tool_icon_url, String, null: true
    def icon_or_tool_icon_url
      load_association(:context_external_tool).then do
        object.icon_or_tool_icon_url
      end
    end
  end
end
