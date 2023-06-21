# frozen_string_literal: true

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
#

module Factories
  def line_item_model(overrides = {})
    assignment_opts = {
      course: overrides[:course] || course_factory(active_course: true),
      submission_types: overrides[:tool] ? "external_tool" : nil,
      external_tool_tag_attributes: if overrides[:tool]
                                      {
                                        url: overrides[:tool].url,
                                        content_type: "context_external_tool",
                                        content_id: overrides[:tool].id
                                      }
                                    else
                                      nil
                                    end
    }.compact
    assignment = overrides[:assignment] || assignment_model(assignment_opts)
    params = base_line_item_params_with_resource_link(assignment, overrides).merge(
      overrides.except(:assignment, :course, :resource_link, :with_resource_link, :tool)
    )
    params[:client_id] = overrides[:client_id]
    params[:client_id] ||= DeveloperKey.create!.id unless assignment.external_tool? || overrides[:with_resource_link]
    Lti::LineItem.create!(params)
  end

  def base_line_item_params(assignment, developer_key = nil)
    {
      score_maximum: 10,
      label: "Test Line Item",
      assignment:,
      client_id: developer_key&.global_id
    }
  end

  def base_line_item_params_with_resource_link(assignment, overrides)
    base_line_item_params(assignment).merge(resource_link: overrides.fetch(
      :resource_link,
      if overrides[:with_resource_link]
        resource_link_model(overrides: overrides.merge(resource_link_uuid: assignment.lti_context_id))
      else
        nil
      end
    ))
  end
end
