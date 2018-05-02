#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Submissions
  class DownloadsController < DownloadsBaseController
    def show
      @submission_for_show = Submissions::SubmissionForShow.new(
        assignment_id: params.fetch(:assignment_id),
        context: @context,
        id: params.fetch(:id),
        preview: params.fetch(:preview, false),
        version: params.fetch(:version, nil)
      )
      begin
        @submission = @submission_for_show.submission
      rescue ActiveRecord::RecordNotFound
        @assignment = @submission_for_show.assignment
        render_user_not_found and return
      end

      super
    end
  end
end
