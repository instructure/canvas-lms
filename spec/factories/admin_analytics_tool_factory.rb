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

module Factories
  def admin_analytics_tool_factory(context: Account.default)
    context.context_external_tools.create!(
      name: "Admin Analytics",
      shared_secret: "1",
      consumer_key: "1",
      url: "http://admin_analytics.example.com/",
      tool_id: ContextExternalTool::ADMIN_ANALYTICS,
      settings: {
        account_navigation: {
          canvas_icon_class: "icon-analytics"
        }.with_indifferent_access
      }
    )
  end
end
