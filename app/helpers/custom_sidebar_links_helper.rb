#
# Copyright (C) 2016 - present Instructure, Inc.
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

# extension points for plugins to add sidebar links
# plugins should call super and append their additional links to the base ones
# return an array of hashes containing +url+, +icon_class+, and +text+
module CustomSidebarLinksHelper
  # LTI tools we will insert custom links for
  TOOL_IDS = [ContextExternalTool::ANALYTICS_2].freeze

  # add a link to the account page sidebar
  # @account is the account
  def account_custom_links
    []
  end

  # add a link to the course page sidebar
  # @context is the course
  def course_custom_links
    base_placements = RequestCache.cache('course_placement_info', @context) do
      external_tools_display_hashes(:course_navigation, tool_ids: TOOL_IDS)
    end
    base_placements.map do |placement|
      {
        text: placement[:title],
        url: placement[:base_url],
        icon_class: placement[:canvas_icon_class] || 'icon-lti',
        tool_id: placement[:tool_id]
      }
    end
  end

  # add a link to a user roster or profile page
  # @context is the course
  def roster_user_custom_links(user)
    return [] unless @context.is_a?(Course) && @context.user_has_been_student?(user)
    base_placements = RequestCache.cache('user_in_course_placement_info', @context) do
      external_tools_display_hashes(:student_context_card, tool_ids: TOOL_IDS)
    end
    base_placements.map do |placement|
      {
        text: placement[:title],
        url: placement[:base_url] + "&student_id=#{user.id}",
        icon_class: placement[:canvas_icon_class] || 'icon-lti',
        tool_id: placement[:tool_id]
      }
    end
  end
end
