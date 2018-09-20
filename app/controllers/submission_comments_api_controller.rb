#
# Copyright (C) 2013 - present Instructure, Inc.
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

# @API Submission Comments
#
# This API can be used to create files to attach to submission comments.  The
# submission comments themselves can be created using the Submissions API.
class SubmissionCommentsApiController < ApplicationController
  before_action :require_context

  include Api::V1::Attachment

  # @API Upload a file
  #
  # Upload a file to attach to a submission comment
  #
  # See the {file:file_uploads.html File Upload Documentation} for details on the file upload workflow.
  #
  # The final step of the file upload workflow will return the attachment data,
  # including the new file id. The caller can then PUT the file_id to the
  # submission API to attach it to a comment
  def create_file
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = api_find(@context.students_visible_to(@current_user, include: :inactive),
                     params[:user_id])

    if authorized_action?(@assignment, @current_user,
                          :attach_submission_comment_files)
      api_attachment_preflight(@assignment, request, check_quota: false)
    end
  end
end
