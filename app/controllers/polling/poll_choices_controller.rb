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
  # @API PollChoices
  # Manage choices for polls
  #
  # @model PollChoice
  #   {
  #     "id": "PollChoice",
  #     "required": ["id", "poll_id", "text"],
  #     "properties": {
  #       "id": {
  #         "description": "The unique identifier for the poll choice.",
  #         "example": 1023,
  #         "type": "integer"
  #       },
  #       "poll_id": {
  #         "description": "The id of the poll this poll choice belongs to.",
  #         "example": 1779,
  #         "type": "integer"
  #       },
  #       "is_correct": {
  #         "description": "Specifies whether or not this poll choice is a 'correct' choice.",
  #         "example": "true",
  #         "type": "boolean"
  #       },
  #       "text": {
  #         "description": "The text of the poll choice.",
  #         "type": "string",
  #         "example": "Choice A"
  #       },
  #       "position": {
  #         "description": "The order of the poll choice in relation to it's sibling poll choices.",
  #         "type": "integer",
  #         "example": 1
  #       }
  #     }
  #   }
  #
  class PollChoicesController < ApplicationController
    include ::Filters::Polling

    before_action :require_user
    before_action :require_poll

    # @API List poll choices in a poll
    #
    # Returns the paginated list of PollChoices in this poll.
    #
    # @example_response
    #   {
    #     "poll_choices": [PollChoice]
    #   }
    #
    def index
      if authorized_action(@poll, @current_user, :read)
        @poll_choices = @poll.poll_choices
        json, meta = paginate_for(@poll_choices)

        render json: serialize_jsonapi(json, meta)
      end
    end

    # @API Get a single poll choice
    #
    # Returns the poll choice with the given id
    #
    # @example_response
    #   {
    #     "poll_choices": [PollChoice]
    #   }
    #
    def show
      @poll_choice = @poll.poll_choices.find(params[:id])
      if authorized_action(@poll, @current_user, :read)
        render json: serialize_jsonapi(@poll_choice)
      end
    end

    # @API Create a single poll choice
    #
    # Create a new poll choice for this poll
    #
    # @argument poll_choices[][text] [Required, String]
    #   The descriptive text of the poll choice.
    #
    # @argument poll_choices[][is_correct] [Boolean]
    #   Whether this poll choice is considered correct or not. Defaults to false.
    #
    # @argument poll_choices[][position] [Integer]
    #   The order this poll choice should be returned in the context it's sibling poll choices.
    #
    # @example_response
    #   {
    #     "poll_choices": [PollChoice]
    #   }
    #
    def create
      poll_choice_params = get_poll_choice_params
      @poll_choice = @poll.poll_choices.new(poll_choice_params)
      @poll_choice.is_correct = false if poll_choice_params && poll_choice_params[:is_correct].blank?

      if authorized_action(@poll, @current_user, :update)
        if @poll_choice.save
          render json: serialize_jsonapi(@poll_choice)
        else
          render json: @poll_choice.errors, status: :bad_request
        end
      end
    end

    # @API Update a single poll choice
    #
    # Update an existing poll choice for this poll
    #
    # @argument poll_choices[][text] [Required, String]
    #   The descriptive text of the poll choice.
    #
    # @argument poll_choices[][is_correct] [Boolean]
    #   Whether this poll choice is considered correct or not.  Defaults to false.
    #
    # @argument poll_choices[][position] [Integer]
    #   The order this poll choice should be returned in the context it's sibling poll choices.
    #
    # @example_response
    #   {
    #     "poll_choices": [PollChoice]
    #   }
    #
    def update
      poll_choice_params = get_poll_choice_params
      @poll_choice = @poll.poll_choices.find(params[:id])

      if poll_choice_params && poll_choice_params[:is_correct].blank?
        poll_choice_params[:is_correct] = @poll_choice.is_correct
      end

      if authorized_action(@poll, @current_user, :update)
        if @poll_choice.update_attributes(poll_choice_params)
          render json: serialize_jsonapi(@poll_choice)
        else
          render json: @poll_choice.errors, status: :bad_request
        end
      end
    end

    # @API Delete a poll choice
    #
    # <b>204 No Content</b> response code is returned if the deletion was successful.
    def destroy
      @poll_choice = @poll.poll_choices.find(params[:id])

      if authorized_action(@poll, @current_user, :delete)
        @poll_choice.destroy
        head :no_content
      end
    end

    protected
    def paginate_for(poll_choices)
      meta = {}
      json = if accepts_jsonapi?
              poll_choices, meta = Api.jsonapi_paginate(poll_choices, self, api_v1_poll_choices_url(@poll))
              meta[:primaryCollection] = 'poll_choices'
              poll_choices
             else
               Api.paginate(poll_choices, self, api_v1_poll_choices_url(@poll))
             end

      return json, meta
    end

    def serialize_jsonapi(poll_choices, meta = {})
      poll_choices = Array.wrap(poll_choices)

      Canvas::APIArraySerializer.new(poll_choices, {
        each_serializer: Polling::PollChoiceSerializer,
        controller: self,
        root: :poll_choices,
        meta: meta,
        scope: @current_user,
        include_root: false
      }).as_json
    end

    def get_poll_choice_params
      params.require(:poll_choices)[0].permit(:text, :is_correct, :position)
    end

  end
end
