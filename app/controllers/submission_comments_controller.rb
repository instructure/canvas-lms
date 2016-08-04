#
# Copyright (C) 2011 Instructure, Inc.
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

class SubmissionCommentsController < ApplicationController
  before_action :require_user

  def update
    submission_comment = SubmissionComment.find(params[:id])
    if authorized_action(submission_comment, @current_user, :update)
      submission_comment.reload unless submission_comment.update(submission_comment_params)

      respond_to do |format|
        format.json { render json: submission_comment }
      end
    end
  end

  def destroy
    submission_comment = SubmissionComment.find(params[:id])
    if authorized_action(submission_comment, @current_user, :delete)
      submission_comment.destroy
      respond_to do |format|
        format.json { render json: submission_comment }
      end
    end
  end

  private

  def submission_comment_params
    strong_params.require(:submission_comment).permit(:draft)
  end
end
