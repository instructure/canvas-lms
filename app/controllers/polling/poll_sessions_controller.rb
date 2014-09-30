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
  #     "required": ["id", "poll_id", "course_id"],
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
  #       },
  #       "created_at": {
  #         "description": "The time at which the poll session was created.",
  #         "example": "2014-01-07T15:16:18Z",
  #         "type": "string",
  #         "format": "date-time"
  #       },
  #       "results": {
  #         "description": "The results of the submissions of the poll. Each key is the poll choice id, and the value is the count of submissions.",
  #         "example": { "144": 10, "145": 3, "146": 27, "147": 8 },
  #         "type": "object"
  #       },
  #       "poll_submissions": {
  #         "description": "If the poll session has public results, this will return an array of all submissions, viewable by both students and teachers. If the results are not public, for students it will return their submission only.",
  #         "$ref": "PollSubmission"
  #       }
  #     }
  #   }
  #
  class PollSessionsController < ApplicationController
    include Filters::Polling

    before_filter :require_user
    before_filter :require_poll, except: [:opened, :closed]

    # @API List poll sessions for a poll
    # @beta
    #
    # Returns the list of PollSessions in this poll.
    #
    # @example_response
    #   {
    #     "poll_sessions": [PollSession]
    #   }
    #
    def index
      if authorized_action(@poll, @current_user, :update)
        @poll_sessions = @poll.poll_sessions
        json, meta = paginate_for(@poll_sessions, api_v1_poll_sessions_url(@poll))

        render json: serialize_jsonapi(json, meta)
      end
    end

    # @API Get the results for a single poll session
    # @beta
    #
    # Returns the poll session with the given id
    #
    # @example_response
    #   {
    #     "poll_sessions": [PollSession]
    #   }
    #
    def show
      @poll_session = @poll.poll_sessions.find(params[:id])

      if authorized_action(@poll_session, @current_user, :read)
        render json: serialize_jsonapi(@poll_session)
      end
    end

    # @API Create a single poll session
    # @beta
    #
    # Create a new poll session for this poll
    #
    # @argument poll_sessions[][course_id] [Required, Integer]
    #   The id of the course this session is associated with.
    #
    # @argument poll_sessions[][course_section_id] [Integer]
    #   The id of the course section this session is associated with.
    #
    # @argument poll_sessions[][has_public_results] [Boolean]
    #   Whether or not results are viewable by students.
    #
    # @example_response
    #   {
    #     "poll_sessions": [PollSession]
    #   }
    #
    def create
      poll_session_params = params[:poll_sessions][0]

      if course_id = poll_session_params.delete(:course_id)
        @course = Course.find(course_id)
      end

      raise ActiveRecord::RecordNotFound.new(I18n.t("polling.poll_sessions.errors.course_required", "Course is required.")) unless @course

      if course_section_id = poll_session_params.delete(:course_section_id)
        @course_section = @course.course_sections.find(course_section_id)
      end

      @poll_session = @course.poll_sessions.build(poll_session_params.merge(poll: @poll,
                                                                          course_section: @course_section))

      @poll_session.has_public_results = false if poll_session_params[:has_public_results].blank?

      if authorized_action(@poll, @current_user, :create) && authorized_action(@course, @current_user, :update)
        if @poll_session.save
          render json: serialize_jsonapi(@poll_session)
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
    # @argument poll_sessions[][course_id] [Integer]
    #   The id of the course this session is associated with.
    #
    # @argument poll_sessions[][course_section_id] [Integer]
    #   The id of the course section this session is associated with.
    #
    # @argument poll_sessions[][has_public_results] [Boolean]
    #   Whether or not results are viewable by students.
    #
    # @example_response
    #   {
    #     "poll_sessions": [PollSession]
    #   }
    #
    def update
      @poll_session = @poll.poll_sessions.find(params[:id])
      poll_session_params = params[:poll_sessions][0]
      if authorized_action(@poll, @current_user, :update)
        if @poll_session.update_attributes(poll_session_params)
          render json: serialize_jsonapi(@poll_session)
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

    # @API Open a poll session
    # @beta
    #
    # @example_response
    #   {
    #     "poll_sessions": [PollSession]
    #   }
    #
    def open
      @poll_session = @poll.poll_sessions.find(params[:id])

      if authorized_action(@poll_session, @current_user, :publish)
        @poll_session.publish!
        render json: serialize_jsonapi(@poll_session)
      end
    end

    # @API Close an opened poll session
    # @beta
    #
    # @example_response
    #   {
    #     "poll_sessions": [PollSession]
    #   }
    #
    def close
      @poll_session = @poll.poll_sessions.find(params[:id])

      if authorized_action(@poll_session, @current_user, :publish)
        @poll_session.close!
        render json: serialize_jsonapi(@poll_session)
      end
    end

    # @API List opened poll sessions
    # @beta
    #
    # Lists all opened poll sessions available to the current user.
    #
    # @example_response
    #   {
    #     "poll_sessions": [PollSession]
    #   }
    #
    def opened
      @poll_sessions = Polling::PollSession.available_for(@current_user).where(is_published: true)
      json, meta = paginate_for(@poll_sessions, api_v1_poll_sessions_opened_url)
      render json: serialize_jsonapi(json, meta)
    end

    # @API List closed poll sessions
    # @beta
    #
    # Lists all closed poll sessions available to the current user.
    #
    # @example_response
    #   {
    #     "poll_sessions": [PollSession]
    #   }
    #
    def closed
      @poll_sessions = Polling::PollSession.available_for(@current_user).where(is_published: false)
      json, meta = paginate_for(@poll_sessions, api_v1_poll_sessions_closed_url)
      render json: serialize_jsonapi(json, meta)
    end

    protected
    def paginate_for(poll_sessions, api_url="")
      meta = {}
      json = if accepts_jsonapi?
              poll_sessions, meta = Api.jsonapi_paginate(poll_sessions, self, api_url)
              meta[:primaryCollection] = 'poll_sessions'
              poll_sessions
             else
               Api.paginate(poll_sessions, self, api_url)
             end

      return json, meta
    end


    def serialize_jsonapi(poll_sessions, meta = {})
      poll_sessions = Array.wrap(poll_sessions)

      Canvas::APIArraySerializer.new(poll_sessions, {
        each_serializer: Polling::PollSessionSerializer,
        controller: self,
        root: :poll_sessions,
        meta: meta,
        scope: @current_user,
        include_root: false
      }).as_json
    end

  end
end
