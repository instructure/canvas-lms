# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module DataFixup::CreateQuizLtiNavigationPlacements
  def self.run
    quiz_lti_tools = ContextExternalTool.quiz_lti
                                        .where(context_type: "Account").where.not(workflow_state: "deleted")

    quiz_lti_tools.preload(:context_external_tool_placements).find_each do |quiz_tool|
      placements = quiz_tool.context_external_tool_placements

      ["account", "course"].each do |context|
        placement_type = "#{context}_navigation"

        if placements.find_by(placement_type:).blank?
          ContextExternalToolPlacement.create(placement_type:, context_external_tool_id: quiz_tool.id)
        end
      end
    end
  end
end
