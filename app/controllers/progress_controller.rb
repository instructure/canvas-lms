#
# Copyright (C) 2013 Instructure, Inc.
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

# @API Progress
#
# API for querying the progress of asynchronous API operations.
#
# @object Progress
#     {
#       // the ID of the Progress object
#       "id": 1,
#
#       // the context owning the job.
#       "context_id": 1,
#       "context_type": "Account",
#
#       // the id of the user who started the job
#       "user_id": 123,
#
#       // the type of operation
#       "tag": "course_batch_update",
#
#       // percent completed
#       "completion": 100,
#
#       // the state of the job
#       // one of 'queued', 'running', 'completed', 'failed'
#       "workflow_state": "completed",
#
#       // the time the job was created
#       "created_at": "2013-01-15T15:00:00Z",
#
#       // the time the job was last updated
#       "updated_at": "2013-01-15T15:04:00Z",
#
#       // optional details about the job
#       "message": "17 courses processed"
#
#       // url where a progress update can be retrieved
#       "url": "https://canvas.example.edu/api/v1/progress/1"
#     }
#
class ProgressController < ApplicationController

  include Api::V1::Progress

  # @API Query progress
  # Return completion and status information about an asynchronous job
  #
  # @returns Progress
  def show
    progress = Progress.find(params[:id])
    if authorized_action(progress.context, @current_user, :read)
      render :json => progress_json(progress, @current_user, session)
    end
  end
end
