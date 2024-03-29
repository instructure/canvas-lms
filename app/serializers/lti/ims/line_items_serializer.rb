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

module Lti::IMS
  class LineItemsSerializer
    def initialize(line_item, line_item_url, include_launch_url = false)
      @line_item = line_item
      @line_item_url = line_item_url
      @include_launch_url = include_launch_url
    end

    def as_json
      {
        id: @line_item_url,
        scoreMaximum: @line_item.score_maximum,
        label: @line_item.label,
        resourceId: @line_item.resource_id,
        tag: @line_item.tag,
        startDateTime: @line_item.start_date_time,
        endDateTime: @line_item.end_date_time,
        resourceLinkId: @line_item.resource_link&.resource_link_uuid,
      }.merge(@line_item.extensions)
        .merge(@include_launch_url ? @line_item.launch_url_extension : {})
        .compact
    end
  end
end
