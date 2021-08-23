# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Lti::Ims
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
  #           "description": "url where a progress update can be retrieved with an LTI access token",
  #           "example": "https://canvas.example.edu/api/lti/courses/1/progress/1",
  #           "type": "string"
  #         }
  #       }
  #     }
  #
  class ProgressController < ApplicationController
    include Concerns::AdvantageServices
    include Api::V1::Progress

    before_action :verify_assignment_tool_association

    # @API Query progress
    # Return completion and status information about an asynchronous job
    #
    # @returns Progress
    def show
      # @current_user and session aren't present in LTI requests
      render json:
               progress_json(progress, nil, nil).tap { |hash| hash['url'] = lti_progress_show_url }
    end

    private

    def context
      @_context ||= Course.not_completed.find(params[:course_id])
    end

    def scopes_matcher
      self.class.all_of(TokenScopes::LTI_AGS_SHOW_PROGRESS_SCOPE)
    end

    def progress
      @_progress ||= Progress.find(params[:id])
    end

    def verify_assignment_tool_association
      unless progress.context.is_a? Assignment
        render_error 'Tool does not have permission to view a Progress not associated with an Assignment',
                     :forbidden
      end

      if tool !=
           ContextExternalTool.from_content_tag(
             progress.context.external_tool_tag,
             progress.context
           )
        render_error "Progress associated with Assignment that isn't linked to this Tool",
                     :unprocessable_entity
      end
    end
  end
end
