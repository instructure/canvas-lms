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

module Submissions
  class AnonymousDownloadsController < DownloadsBaseController
    def show
      @submission_for_show = Submissions::AnonymousSubmissionForShow.new(
        anonymous_id: params.fetch(:anonymous_id),
        assignment_id: params.fetch(:assignment_id),
        context: @context,
        preview: params.fetch(:preview, false),
        version: params.fetch(:version, nil)
      )
      @submission = @submission_for_show.submission
      @assignment = @submission_for_show.assignment

      super
    end
  end
end
