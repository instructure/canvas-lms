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
  #         "poll_choice": {
  #           "description": "The chosen poll choice for this submission.  See the Poll Choice API for details.",
  #           "$ref": "PollChoice"
  #         }
  #       }
  #    }
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
    # @returns PollSubmission
    def show
      @poll_submission = @poll_session.poll_submissions.find(params[:id])
      if authorized_action(@poll_submission, @current_user, :read)
        render json: serialize_json(@poll_submission, true)
      end
    end

    # @API Create a single poll submission
    # @beta
    #
    # Create a new poll submission for this poll session
    #
    # @argument poll_submission[poll_choice_id] [Required, Integer]
    #   The chosen poll choice for this submission.
    #
    # @returns PollSubmission
    def create
      @poll_submission = @poll_session.poll_submissions.new
      @poll_submission.poll = @poll
      @poll_submission.user = @current_user
      @poll_submission.poll_choice = @poll.poll_choices.find(params[:poll_submission][:poll_choice_id])

      if authorized_action(@poll_submission, @current_user, :submit)
        if @poll_submission.save
          render json: serialize_json(@poll_submission)
        else
          render json: @poll_submission.errors, status: :bad_request
        end
      end
    end

    protected
    def serialize_json(poll_submissions, single=false)
      poll_submissions = Array(poll_submissions)

      serialized_set = poll_submissions.map do |poll_submission|
        Polling::PollSubmissionSerializer.new(poll_submission, {
          controller: self,
          root: false,
          include_root: false,
          scope: @current_user
        }).as_json
      end
      single ? serialized_set.first : serialized_set
    end

  end
end
