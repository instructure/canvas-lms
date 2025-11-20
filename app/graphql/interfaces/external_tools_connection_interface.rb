# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

require_dependency "types/external_tool_type"

module Interfaces::ExternalToolsConnectionInterface
  include Interfaces::BaseInterface

  class ExternalToolFilterInputType < Types::BaseInputObject
    graphql_name "ExternalToolFilterInput"

    argument :placement, ::Types::ExternalToolPlacementType, required: false, default_value: nil
    argument :placement_list, [::Types::ExternalToolPlacementType], required: false, default_value: nil
    argument :state, ::Types::ExternalToolStateType, required: false, default_value: nil
  end

  field :external_tools_connection,
        ::Types::ExternalToolType.connection_type,
        <<~MD,
          returns a list of external tools.
        MD
        null: true do
    argument :filter, ExternalToolFilterInputType, required: false, default_value: {}
  end
  def external_tools_connection(course:, filter: {})
    placement_param = if filter.placement
                        [filter.placement]
                      elsif filter.placement_list
                        filter.placement_list
                      end

    scope = Lti::ContextToolFinder.all_tools_for(course, placements: placement_param)

    filter.state.nil? ? scope : scope.where(workflow_state: filter.state)
  end
end
