# frozen_string_literal: true

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

# @API Progress
#
# API for querying the progress of asynchronous API operations.
#
# @model Progress
#     {
#       "id": "Progress",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the Progress object",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_id": {
#           "description": "the context owning the job.",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_type": {
#           "example": "Account",
#           "type": "string"
#         },
#         "user_id": {
#           "description": "the id of the user who started the job",
#           "example": 123,
#           "type": "integer"
#         },
#         "tag": {
#           "description": "the type of operation",
#           "example": "course_batch_update",
#           "type": "string"
#         },
#         "completion": {
#           "description": "percent completed",
#           "example": 100,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "the state of the job one of 'queued', 'running', 'completed', 'failed'",
#           "example": "completed",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "queued",
#               "running",
#               "completed",
#               "failed"
#             ]
#           }
#         },
#         "created_at": {
#           "description": "the time the job was created",
#           "example": "2013-01-15T15:00:00Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "the time the job was last updated",
#           "example": "2013-01-15T15:04:00Z",
#           "type": "datetime"
#         },
#         "message": {
#           "description": "optional details about the job",
#           "example": "17 courses processed",
#           "type": "string"
#         },
#         "results": {
#           "description": "optional results of the job. omitted when job is still pending",
#           "example": { "id": "123" },
#           "type": "object"
#         },
#         "url": {
#           "description": "url where a progress update can be retrieved",
#           "example": "https://canvas.example.edu/api/v1/progress/1",
#           "type": "string"
#         }
#       }
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
      render json: progress_json(progress, @current_user, session)
    end
  end

  # @API Cancel progress
  # Cancel an asynchronous job associated with a Progress object
  # If you include "message" in the POSTed data, it will be set on
  # the Progress and returned. This is handy to distinguish between
  # cancel and fail for a workflow_state of "failed".
  #
  # @returns Progress
  def cancel
    progress = Progress.find(params[:id])
    if authorized_action(progress, @current_user, :cancel)
      progress.update!(workflow_state: "failed", message: params[:message])
      render json: progress_json(progress, @current_user, session)
    end
  end
end
