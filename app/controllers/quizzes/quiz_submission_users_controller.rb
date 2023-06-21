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
#
module Quizzes
  # @API Quiz Submission User List
  #
  # List of users who have or haven't submitted for a quiz.
  #
  # @argument submitted [Optional, boolean]
  #   If true, return users who have submitted the quiz. If false, return users
  #   who have not submitted the quiz. If not present, returns all students for
  #   the course.
  #
  # @argument includes [Optional, array]
  #   Optional list of resources to include with the response. May include
  #   a string of the name of the resource. Possible values are:
  #   "quiz_submissions".
  #
  # @returns QuizSubmissionUserList
  #
  # @model QuizSubmissionUserList
  #     {
  #       "meta": {
  #         "$ref": "QuizSubmissionUserListMeta",
  #         "description": "contains meta information (such as pagination) for the list of users"
  #       },
  #       "users": {
  #         "$ref": "User",
  #         "description": "list of users that match the query"
  #       }
  #     }
  #
  # @model QuizSubmissionUserListMeta
  #     {
  #       "pagination": {
  #         "$ref": "JSONAPIPagination",
  #         "description": "contains pagination information for the list of users"
  #       }
  #     }
  #
  # @model JSONAPIPagination
  #     {
  #       "per_page": {
  #         "type": "integer",
  #         "description": "number of results per page",
  #         "example": 10
  #       },
  #       "page": {
  #         "type": "integer",
  #         "description": "the current page passed as the ?page= parameter",
  #         "example": 1
  #       },
  #       "template": {
  #         "type": "string",
  #         "description": "URL template for building out other paged URLs for this endpoint",
  #         "example": "https://example.instructure.com/api/v1/courses/1/quizzes/1/submission_users?page={page}"
  #       },
  #       "page_count": {
  #         "type": "integer",
  #         "description": "number of pages for this collection",
  #         "example": 10
  #       },
  #       "count": {
  #         "type": "integer",
  #         "description": "total number of items in this collection",
  #         "example": 100
  #       }
  #     }
  class QuizSubmissionUsersController < ::ApplicationController
    include ::Filters::Quizzes
    before_action :require_context, :require_quiz

    def index
      return unless user_has_teacher_level_access?

      @users = index_users
      includes = Array(params[:include])
      @users, meta = Api.jsonapi_paginate(@users, self, index_base_url, params)
      if includes.include? "quiz_submissions"
        quiz_submissions = QuizSubmission.where(user_id: @users.to_a, quiz_id: @quiz).index_by(&:user_id)
      end
      UserPastLtiId.manual_preload_past_lti_ids(@users, @context) if ["uuid", "lti_id"].any? { |id| includes.include? id }
      users_json = Canvas::APIArraySerializer.new(@users, {
                                                    quiz: @quiz,
                                                    root: :users,
                                                    meta:,
                                                    quiz_submissions:,
                                                    includes:,
                                                    controller: self,
                                                    each_serializer: Quizzes::QuizSubmissionUserSerializer
                                                  })
      render json: users_json.as_json
    end

    def index_users
      if submitted_param?
        submitted? ? submitted_users : unsubmitted_users
      else
        user_finder.all_students_with_visibility
      end
    end

    # @API Send a message to unsubmitted or submitted users for the quiz
    #
    # @argument conversations [QuizUserConversation] - Body and recipients to send the message to.
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
        render json: { status: t("created", "created") }, status: :created
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
          submitted: submitted? ? "true" : "false"
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
