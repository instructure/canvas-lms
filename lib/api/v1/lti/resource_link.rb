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
#

module Api::V1::Lti::ResourceLink
  include Api::V1::Json

  def lti_resource_link_json(resource_link, user, session, type, content_tag_id)
    api_json(resource_link, user, session).tap do |json|
      json["resource_type"] = type
      launch_url = if type == :assignment
                     course_assignment_url(resource_link.context.course, resource_link.context)
                   else
                     retrieve_course_external_tools_url(resource_link.context, resource_link_lookup_uuid: resource_link.lookup_uuid)
                   end
      json["canvas_launch_url"] = launch_url
      if content_tag_id.present?
        json["associated_content_type"] = "ModuleItem"
        json["associated_content_id"] = content_tag_id
      end
    end
  end
end
