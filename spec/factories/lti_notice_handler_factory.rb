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

module Factories
  def lti_notice_handler_model(overrides = {})
    context_external_tool = overrides.delete(:context_external_tool)
    notice_type = overrides.delete(:notice_type) || "LtiAssetProcessorSubmissionNotice"
    url = if context_external_tool.url
            "#{context_external_tool.url}/handler"
          else
            "https://example.com/handler"
          end

    params = {
      context_external_tool:,
      notice_type:,
      url:,
      root_account: context_external_tool.root_account,
      account: context_external_tool.account || context_external_tool.context
    }.merge(overrides)

    Lti::NoticeHandler.create!(params)
  end
end
