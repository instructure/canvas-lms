# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
  #         },
  #         "total_results": {
  #           "description": "An aggregate of the results of all associated poll sessions, with the poll choice id as the key, and the aggregated submission count as the value.",
  #           "example": { "543": 20, "544": 5, "545": 17 },
  #           "type": "object"
  #         }
  #       }
  #    }
  #
  class PollsController < ApplicationController
    include ::Filters::Polling

    before_action :require_user

    # @API List polls
    #
    # Returns the paginated list of polls for the current user.
    #
    # @example_response
    #   {
    #     "polls": [Poll]
    #   }
    #
    def index
      @polls = @current_user.polls.order("created_at DESC")
      json, meta = paginate_for(@polls)

      render json: serialize_jsonapi(json, meta)
    end

    # @API Get a single poll
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
    #
    # Create a new poll for the current user
    #
    # @argument polls[][question] [Required, String]
    #   The title of the poll.
    #
    # @argument polls[][description] [String]
    #   A brief description or instructions for the poll.
    #
    # @example_response
    #   {
    #     "polls": [Poll]
    #   }
    #
    def create
      @poll = @current_user.polls.new(get_poll_params)
      if authorized_action(@poll, @current_user, :create)
        if @poll.save
          render json: serialize_jsonapi(@poll)
        else
          render json: @poll.errors, status: :bad_request
        end
      end
    end

    # @API Update a single poll
    #
    # Update an existing poll belonging to the current user
    #
    # @argument polls[][question] [Required, String]
    #   The title of the poll.
    #
    # @argument polls[][description] [String]
    #   A brief description or instructions for the poll.
    #
    # @example_response
    #   {
    #     "polls": [Poll]
    #   }
    #
    def update
      @poll = Polling::Poll.find(params[:id])
      poll_params = get_poll_params

      if authorized_action(@poll, @current_user, :update)
        poll_params.delete(:is_correct) if poll_params && poll_params[:is_correct].blank?

        if @poll.update(poll_params)
          render json: serialize_jsonapi(@poll)
        else
          render json: @poll.errors, status: :bad_request
        end
      end
    end

    # @API Delete a poll
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

    def paginate_for(polls)
      meta = {}
      json = if accepts_jsonapi?
               polls, meta = Api.jsonapi_paginate(polls, self, api_v1_polls_url)
               meta[:primaryCollection] = "polls"
               polls
             else
               Api.paginate(polls, self, api_v1_polls_url)
             end

      [json, meta]
    end

    def serialize_jsonapi(polls, meta = {})
      polls = Array.wrap(polls)

      Canvas::APIArraySerializer.new(polls, {
                                       each_serializer: Polling::PollSerializer,
                                       controller: self,
                                       root: :polls,
                                       meta:,
                                       scope: @current_user,
                                       include_root: false
                                     }).as_json
    end

    def get_poll_params
      params.require(:polls)[0].permit(:question, :description)
    end
  end
end
