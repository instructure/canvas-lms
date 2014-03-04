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
#
module Quizzes
  class QuizSubmissionUsersController < ::ApplicationController
    include Filters::Quizzes
    before_filter :require_context, :require_quiz
    # @API List of users who have or haven't submitted for a quiz
    # @beta
    #
    # @argument submitted [Optional, boolean]
    #   If true, return users who have submitted the quiz. If false, return users
    #   who have not submitted the quiz. If not present, returns all students for
    #   the course.
    #
    # @returns QuizSubmissionUserList
    #
    # @model QuizSubmissionUserList
    #
    # {
    #   "meta": {
    #     "$ref": "QuizSubmissionUserListMeta",
    #     "description": "contains meta information (such as pagination) for the list of users"
    #   },
    #   "users": {
    #     "$ref": "User",
    #     "description": "list of users that match the query"
    #   }
    # }
    #
    # @model QuizSubmissionUserListMeta
    #
    # {
    #   "pagination": {
    #     "$ref": "JSONAPIPagination",
    #     "description": "contains pagination information for the list of users"
    #   }
    # }
    #
    # @model JSONAPIPagination
    #
    # {
    #   "per_page": {
    #     "type": "integer",
    #     "description": "number of results per page",
    #     "example": 10
    #   },
    #   "page": {
    #     "type": "integer",
    #     "description": "the current page passed as the ?page= parameter",
    #     "example": 1
    #   },
    #   "template": {
    #     "type": "string",
    #     "description": "URL template for building out other paged URLs for this endpoint",
    #     "example": "https://example.instructure.com/api/v1/courses/1/quizzes/1/submission_users?page={page}"
    #   },
    #   "page_count": {
    #     "type": "integer",
    #     "description": "number of pages for this collection",
    #     "example": 10
    #   },
    #   "count": {
    #     "type": "integer",
    #     "description": "total number of items in this collection",
    #     "example": 100
    #   }
    # }
    def index
      return unless user_has_teacher_level_access?
      @users = if submitted_param?
        @users = submitted? ? submitted_users : unsubmitted_users
      else
        @users = user_finder.all_students
      end

      @users, meta = Api.jsonapi_paginate(@users, self, index_base_url, page: params[:page])
      users_json = @users.map { |user| user_json(user, @current_user, session) }

      render json: { meta: meta, users: users_json }
    end

    # @API Send a message to unsubmitted or submitted users for the quiz
    # @beta
    #
    # @param conversations [QuizUserConversation] - Body and recipients to send the message to.
    #
    # @model QuizUserConversation
    #
    # {
    #   "body": {
    #     "type": "string",
    #     "description": "message body of the conversation to be created",
    #     "example": "Please take the quiz."
    #   },
    #   "recipients": {
    #     "type": "string",
    #     "description": "Who to send the message to. May be either 'submitted' or 'unsubmitted'",
    #     "example": "submitted"
    #   },
    #   "subject": {
    #     "type": "string",
    #     "description": "Subject of the new Conversation created",
    #     "example": "ATTN: Quiz 101 Students"
    #   }
    # }
    def message
      return unless user_has_teacher_level_access?
      @conversation = Array(params[:conversations]).first
      if @conversation
        send_message
        render json: { status: t('created', 'created') }, status: :created
      else
        render json: [], status: :invalid_request
      end
    end

    private
    def index_base_url
      if submitted_param?
        api_v1_course_quiz_submission_users_url(
          @quiz.context,
          @quiz,
          submitted: submitted? ? 'true' : 'false'
        )
      else
        api_v1_course_quiz_submission_users_url(@quiz.context, @quiz)
      end
    end

    def submitted_param?
      params.key?(:submitted)
    end

    def submitted?
      ::Canvas::Plugin.value_to_boolean(params[:submitted])
    end

    def submitted_users
      user_finder.submitted_students
    end

    def unsubmitted_users
      user_finder.unsubmitted_students
    end

    def user_finder
      @user_finder ||= Quizzes::QuizUserFinder.new(@quiz, @current_user)
    end

    def send_message
      Quizzes::QuizUserMessager.new(
        conversation: @conversation,
        root_account_id: @domain_root_account.id,
        async: true,
        sender: @current_user,
        quiz: @quiz
      ).send
    end

    def user_has_teacher_level_access?
      authorized_action(@quiz, @current_user, [:grade, :read_statistics])
    end
  end
end
