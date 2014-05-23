#
# Copyright (C) 2014 Instructure, Inc.
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

module Polling
  # @API PollSubmissions
  # @beta
  # Manage submissions for polls
  #
  # @model PollSubmission
  #    {
  #       "id": "PollSubmission",
  #       "required": ["id", "poll_choice"],
  #       "properties": {
  #         "id": {
  #           "description": "The unique identifier for the account role/user assignment.",
  #           "example": 1023,
  #           "type": "integer"
  #         },
  #         "poll_choice_id": {
  #           "description": "The id of the chosen poll choice for this submission.",
  #           "example": 55,
  #           "type": "integer"
  #         }
  #       }
  #    }
  #
  class PollSubmissionsController < ApplicationController
    include Filters::Polling

    before_filter :require_user
    before_filter :require_poll
    before_filter :require_poll_session

    # @API Get a single poll submission
    # @beta
    #
    # Returns the poll submission with the given id
    #
    # @example_response
    #   {
    #     "poll_submissions": [PollSubmission]
    #   }
    #
    def show
      @poll_submission = @poll_session.poll_submissions.find(params[:id])
      if authorized_action(@poll_submission, @current_user, :read)
        render json: serialize_jsonapi(@poll_submission)
      end
    end

    # @API Create a single poll submission
    # @beta
    #
    # Create a new poll submission for this poll session
    #
    # @argument poll_submissions[][poll_choice_id] [Required, Integer]
    #   The chosen poll choice for this submission.
    #
    # @example_response
    #   {
    #     "poll_submissions": [PollSubmission]
    #   }
    #
    def create
      poll_submission_params = params[:poll_submissions][0]
      @poll_submission = @poll_session.poll_submissions.new
      @poll_submission.poll = @poll
      @poll_submission.user = @current_user
      @poll_submission.poll_choice = @poll.poll_choices.find(poll_submission_params[:poll_choice_id])

      if authorized_action(@poll_submission, @current_user, :submit)
        if @poll_submission.save
          render json: serialize_jsonapi(@poll_submission)
        else
          render json: @poll_submission.errors, status: :bad_request
        end
      end
    end

    protected
    def serialize_jsonapi(poll_submissions)
      poll_submissions = Array.wrap(poll_submissions)

      serialized_set = Canvas::APIArraySerializer.new(poll_submissions, {
        each_serializer: Polling::PollSubmissionSerializer,
        controller: self,
        root: false,
        scope: @current_user,
        include_root: false
      }).as_json

      { poll_submissions: serialized_set }
    end

  end
end
