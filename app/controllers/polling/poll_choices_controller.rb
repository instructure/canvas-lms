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

# @API PollChoices
# @beta
# Manage choices for polls
#
# @model PollChoice
#   {
#     "id": "PollChoice",
#     "required": ["id", "text"],
#     "properties": {
#       "id": {
#         "description": "The unique identifier for the poll choice.",
#         "example": 1023,
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
#       }
#     }
#   }
#
module Polling
  class PollChoicesController < ApplicationController
    include Filters::Polling

    before_filter :require_user
    before_filter :require_course
    before_filter :require_poll

    # @API List poll choices in a poll
    # @beta
    #
    # Returns the list of PollChoices in this poll.
    #
    # @argument poll_id [Required, Integer]
    #   The associated poll's unique identifier
    #
    # @returns [PollChoice]
    def index
      if authorized_action(@poll, @current_user, :read)
        @poll_choices = @poll.poll_choices
        @poll_choices = Api.paginate(@poll_choices, self, api_v1_course_poll_choices_url(@course, @poll))

        render json: serialize_json(@poll_choices)
      end
    end

    # @API Get a single poll choice
    # @beta
    #
    # Returns the poll choice with the given id
    #
    # @argument poll_id [Required, Integer]
    #   The associated poll's unique identifier
    #
    # @argument id [Required, Integer]
    #   The poll choice unique identifier.
    #
    # @returns PollChoice
    def show
      @poll_choice = @poll.poll_choices.find(params[:id])

      if authorized_action(@poll, @current_user, :read)
        render json: serialize_json(@poll_choice, true)
      end
    end

    # @API Create a single poll choice
    # @beta
    #
    # Create a new poll choice for this poll
    #
    # @argument poll_id [Required, Integer]
    #   The associated poll's unique identifier
    #
    # @argument poll_choice[text] [Required, String]
    #   The descriptive text of the poll choice.
    #
    # @argument poll_choice[is_correct] [Optional, Boolean]
    #   Whether this poll choice is considered correct or not. Defaults to false.
    #
    # @returns PollChoice
    def create
      @poll_choice = @poll.poll_choices.new(params[:poll_choice])

      if authorized_action(@poll, @current_user, :create)
        if @poll_choice.save
          render json: serialize_json(@poll_choice)
        else
          render json: @poll_choice.errors, status: :bad_request
        end
      end
    end

    # @API Update a single poll choice
    # @beta
    #
    # Update an existing poll choice for this poll
    #
    # @argument poll_id [Required, Integer]
    #   The associated poll's unique identifier
    #
    # @argument poll_choice[text] [Required, String]
    #   The descriptive text of the poll choice.
    #
    # @argument poll_choice[is_correct] [Optional, Boolean]
    #   Whether this poll choice is considered correct or not.  Defaults to false.
    #
    # @returns Poll
    def update
      @poll_choice = @poll.poll_choices.find(params[:id])

      if authorized_action(@poll, @current_user, :update)
        if @poll_choice.update_attributes(params[:poll_choice])
          render json: serialize_json(@poll_choice)
        else
          render json: @poll_choice.errors, status: :bad_request
        end
      end
    end

    # @API Delete a poll choice
    # @beta
    #
    # @argument poll_id [Required, Integer]
    #   The associated poll's unique identifier
    #
    # @argument id [Required, Integer]
    #   The poll choice's unique identifier
    #
    # <b>204 No Content<b> response code is returned if the deletion was successful.
    def destroy
      @poll_choice = @poll.poll_choices.find(params[:id])

      if authorized_action(@poll, @current_user, :delete)
        @poll_choice.destroy
        head :no_content
      end
    end

    protected
    def serialize_json(poll_choices, single=false)
      poll_choices = Array(poll_choices)

      serialized_set = poll_choices.map do |poll_choice|
        Polling::PollChoiceSerializer.new(poll_choice, {
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
