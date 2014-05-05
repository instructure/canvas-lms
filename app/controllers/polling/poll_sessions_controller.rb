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
  # @API Poll Sessions
  # @beta
  # Manage poll sessions
  #
  # @model PollSession
  #   {
  #     "id": "PollSession",
  #     "required": ["id", "poll_id", "course_id", "course_section_id"],
  #     "properties": {
  #       "id": {
  #         "description": "The unique identifier for the poll session.",
  #         "example": 1023,
  #         "type": "integer"
  #       },
  #       "poll_id": {
  #         "description": "The id of the Poll this poll session is associated with",
  #         "example": 55,
  #         "type": "integer"
  #       },
  #       "course_id": {
  #         "description": "The id of the Course this poll session is associated with",
  #         "example": 1111,
  #         "type": "integer"
  #       },
  #       "course_section_id": {
  #         "description": "The id of the Course Section this poll session is associated with",
  #         "example": 444,
  #         "type": "integer"
  #       },
  #       "is_published": {
  #         "description": "Specifies whether or not this poll session has been published for students to participate in.",
  #         "example": "true",
  #         "type": "boolean"
  #       },
  #       "has_public_results": {
  #         "description": "Specifies whether the results are viewable by students.",
  #         "example": "true",
  #         "type": "boolean"
  #       }
  #     }
  #   }
  #
  class PollSessionsController < ApplicationController
    include Filters::Polling

    before_filter :require_user
    before_filter :require_poll

    # @API List poll sessions for a poll
    # @beta
    #
    # Returns the list of PollSessions in this poll.
    #
    # @returns [PollSession]
    def index
      if authorized_action(@poll, @current_user, :update)
        @poll_sessions = @poll.poll_sessions
        @poll_sessions = Api.paginate(@poll_sessions, self, api_v1_poll_sessions_url(@poll))

        render json: serialize_json(@poll_sessions)
      end
    end

    # @API Get the results for a single poll session
    # @beta
    #
    # Returns the poll session with the given id
    #
    # @returns PollSession
    def show
      @poll_session = @poll.poll_sessions.find(params[:id])

      if authorized_action(@poll_session, @current_user, :read)
        render json: serialize_json(@poll_session, true)
      end
    end

    # @API Create a single poll session
    # @beta
    #
    # Create a new poll session for this poll
    #
    # @argument poll_session[course_id] [Required, Integer]
    #   The id of the course this session is associated with.
    #
    # @argument poll_session[course_section_id] [Required, Integer]
    #   The id of the course section this session is associated with.
    #
    # @argument poll_session[has_public_results] [Optional, Boolean]
    #   Whether or not results are viewable by students.
    #
    # @returns PollSession
    def create
      if params[:poll_session] && course_id = params[:poll_session].delete(:course_id)
        @course = Course.find(course_id)
      end
      raise ActiveRecord::RecordNotFound.new(I18n.t("polling.poll_sessions.errors.course_required", "Course is required.")) unless @course

      @poll_session = @poll.poll_sessions.new(params[:poll_session])
      @poll_session.course = @course

      if authorized_action(@poll, @current_user, :create) && authorized_action(@course, @current_user, :update)
        if @poll_session.save
          render json: serialize_json(@poll_session)
        else
          render json: @poll_session.errors, status: :bad_request
        end
      end
    end

    # @API Update a single poll session
    # @beta
    #
    # Update an existing poll session for this poll
    #
    # @argument poll_session[course_id] [Required, Integer]
    #   The id of the course this session is associated with.
    #
    # @argument poll_session[course_section_id] [Required, Integer]
    #   The id of the course section this session is associated with.
    #
    # @argument poll_session[has_public_results] [Optional, Boolean]
    #   Whether or not results are viewable by students.
    #
    # @returns PollSession
    def update
      @poll_session = @poll.poll_sessions.find(params[:id])

      if authorized_action(@poll, @current_user, :update)
        if @poll_session.update_attributes(params[:poll_session])
          render json: serialize_json(@poll_session)
        else
          render json: @poll_session.errors, status: :bad_request
        end
      end
    end

    # @API Delete a poll session
    # @beta
    #
    # <b>204 No Content</b> response code is returned if the deletion was successful.
    def destroy
      @poll_session = @poll.poll_sessions.find(params[:id])

      if authorized_action(@poll_session, @current_user, :delete)
        @poll_session.destroy
        head :no_content
      end
    end

    # @API Publish a poll session
    # @beta
    #
    # @returns PollSession
    def publish
      @poll_session = @poll.poll_sessions.find(params[:id])

      if authorized_action(@poll_session, @current_user, :publish)
        @poll_session.publish!
        render json: serialize_json(@poll_session)
      end
    end

    # @API Close a published poll session
    # @beta
    #
    # @returns PollSession
    def close
      @poll_session = @poll.poll_sessions.find(params[:id])

      if authorized_action(@poll_session, @current_user, :publish)
        @poll_session.close!
        render json: serialize_json(@poll_session)
      end
    end

    protected
    def serialize_json(poll_sessions, single=false)
      poll_sessions = Array(poll_sessions)

      serialized_set = poll_sessions.map do |poll_session|
        Polling::PollSessionSerializer.new(poll_session, {
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
