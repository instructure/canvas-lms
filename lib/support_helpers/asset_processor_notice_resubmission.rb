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

module SupportHelpers
  class AssetProcessorNoticeResubmission < Fixer
    def initialize(email, after_time, context, tool_id = nil)
      if context.is_a?(Assignment) || context.is_a?(Course)
        @context = context
      else
        raise ArgumentError, "context must be an Assignment or Course"
      end
      @tool_id = tool_id
      super(email, after_time)
    end

    def fix
      @context.submissions.active.unscope(:order).find_each do |submission|
        next if submission.group_id.present? && submission.user_id != submission.real_submitter_id

        Lti::AssetProcessorNotifier.notify_asset_processors(
          submission,
          nil,
          @tool_id
        )
      end
    end
  end
end
