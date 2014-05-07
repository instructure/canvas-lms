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
  #       "required": ["id", "course", "title"],
  #       "properties": {
  #         "id": {
  #           "description": "The unique identifier for the poll.",
  #           "example": 1023,
  #           "type": "integer"
  #         },
  #         "course": {
  #           "description": "The course the poll belongs to.  See the Courses API for details.",
  #           "$ref": "Course"
  #         },
  #         "title": {
  #           "description": "The title of the poll.",
  #           "type": "string",
  #           "example": "A Sample Poll"
  #         },
  #         "description": {
  #           "description": "A short description of the poll.",
  #           "type": "string",
  #           "example": "This poll is to quickly determine what you've learned in the past hour."
  #         }
  #       }
  #    }
  #
  class PollsController < ApplicationController
    include Filters::Polling

    before_filter :require_user
    before_filter :require_course

    # @API List polls in a course
    # @beta
    #
    # Returns the list of polls in this course.
    #
    # @returns [Poll]
    def index
      if authorized_action(@course, @current_user, :read)
        @polls = @course.polls
        @polls = Api.paginate(@polls, self, api_v1_course_polls_url(@course))

        render json: serialize_json(@polls)
      end
    end

    # @API Get a single poll
    # @beta
    #
    # Returns the poll with the given id
    #
    # @argument id [Required, Integer]
    #   The poll unique identifier.
    #
    # @returns Poll
    def show
      @poll = @course.polls.find(params[:id])

      if authorized_action(@poll, @current_user, :read)
        render json: serialize_json(@poll, true)
      end
    end

    # @API Create a single poll
    # @beta
    #
    # Create a new poll for this course
    #
    # @argument poll[title] [Required, String]
    #   The title of the poll.
    #
    # @argument poll[description] [Optional, String]
    #   A brief description or instructions for the poll.
    #
    # @returns Poll
    def create
      @poll = @course.polls.new(params[:poll])

      if authorized_action(@poll, @current_user, :create)
        if @poll.save
          render json: serialize_json(@poll)
        else
          render json: @poll.errors, status: :bad_request
        end

      end
    end

    # @API Update a single poll
    # @beta
    #
    # Update an existing poll for this course
    #
    # @argument poll[title] [Required, String]
    #   The title of the poll.
    #
    # @argument poll[description] [Optional, String]
    #   A brief description or instructions for the poll.
    #
    # @returns Poll
    def update
      @poll = @course.polls.find(params[:id])

      if authorized_action(@poll, @current_user, :update)
        if @poll.update_attributes(params[:poll])
          render json: serialize_json(@poll)
        else
          render json: @poll.errors, status: :bad_request
        end
      end
    end

    # @API Delete a poll
    # @beta
    #
    # @argument id [Required, Integer]
    #   The poll's unique identifier
    #
    # <b>204 No Content<b> response code is returned if the deletion was successful.
    def destroy
      @poll = @course.polls.find(params[:id])

      if authorized_action(@poll, @current_user, :delete)
        @poll.destroy
        head :no_content
      end
    end

    def publish
      if authorized_action(@poll, @current_user, :publish)
      end
    end

    def close
      if authorized_action(@poll, @current_user, :close)
      end
    end

    protected
    def serialize_json(polls, single=false)
      polls = Array(polls)

      serialized_set = polls.map do |poll|
        Polling::PollSerializer.new(poll, {
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
