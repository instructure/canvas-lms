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
  # @API Polls
  # @beta
  # Manage polls
  #
  # @model Poll
  #    {
  #       "id": "Poll",
  #       "required": ["id", "question"],
  #       "properties": {
  #         "id": {
  #           "description": "The unique identifier for the poll.",
  #           "example": 1023,
  #           "type": "integer"
  #         },
  #         "question": {
  #           "description": "The question/title of the poll.",
  #           "type": "string",
  #           "example": "What do you consider most important to your learning in this course?"
  #         },
  #         "description": {
  #           "description": "A short description of the poll.",
  #           "type": "string",
  #           "example": "This poll is to determine what priorities the students in the course have."
  #         },
  #         "created_at": {
  #           "description": "The time at which the poll was created.",
  #           "example": "2014-01-07T15:16:18Z",
  #           "type": "string",
  #           "format": "date-time"
  #         },
  #         "user_id": {
  #           "description": "The unique identifier for the user that created the poll.",
  #           "example": 105,
  #           "type": "integer"
  #         }
  #       }
  #    }
  #
  class PollsController < ApplicationController
    include Filters::Polling

    before_filter :require_user

    # @API List polls
    # @beta
    #
    # Returns the list of polls for the current user.
    #
    # @example_response
    #   {
    #     "polls": [Poll]
    #   }
    #
    def index
      @polls = @current_user.polls.order('created_at DESC')
      @polls = Api.paginate(@polls, self, api_v1_polls_url)

      render json: serialize_jsonapi(@polls)
    end

    # @API Get a single poll
    # @beta
    #
    # Returns the poll with the given id
    #
    # @example_response
    #   {
    #     "polls": [Poll]
    #   }
    #
    def show
      @poll = Polling::Poll.find(params[:id])

      if authorized_action(@poll, @current_user, :read)
        render json: serialize_jsonapi(@poll)
      end
    end

    # @API Create a single poll
    # @beta
    #
    # Create a new poll for the current user
    #
    # @argument polls[][question] [Required, String]
    #   The title of the poll.
    #
    # @argument polls[][description] [Optional, String]
    #   A brief description or instructions for the poll.
    #
    # @example_response
    #   {
    #     "polls": [Poll]
    #   }
    #
    def create
      poll_params = params[:polls][0]
      @poll = @current_user.polls.new(poll_params)
      if authorized_action(@poll, @current_user, :create)
        if @poll.save
          render json: serialize_jsonapi(@poll)
        else
          render json: @poll.errors, status: :bad_request
        end
      end
    end

    # @API Update a single poll
    # @beta
    #
    # Update an existing poll belonging to the current user
    #
    # @argument polls[][question] [Required, String]
    #   The title of the poll.
    #
    # @argument polls[][description] [Optional, String]
    #   A brief description or instructions for the poll.
    #
    # @example_response
    #   {
    #     "polls": [Poll]
    #   }
    #
    def update
      @poll = Polling::Poll.find(params[:id])
      poll_params = params[:polls][0]

      if authorized_action(@poll, @current_user, :update)
        poll_params.delete(:is_correct) if poll_params && poll_params[:is_correct].blank?

        if @poll.update_attributes(poll_params)
          render json: serialize_jsonapi(@poll)
        else
          render json: @poll.errors, status: :bad_request
        end
      end
    end

    # @API Delete a poll
    # @beta
    #
    # <b>204 No Content</b> response code is returned if the deletion was successful.
    def destroy
      @poll = Polling::Poll.find(params[:id])
      if authorized_action(@poll, @current_user, :delete)
        @poll.destroy
        head :no_content
      end
    end

    protected
    def serialize_jsonapi(polls)
      polls = Array.wrap(polls)

      serialized_set = Canvas::APIArraySerializer.new(polls, {
        each_serializer: Polling::PollSerializer,
        controller: self,
        root: false,
        scope: @current_user,
        include_root: false
      }).as_json

      { polls: serialized_set }
    end

  end
end
