# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module NewQuizzes
  # @API New Quizzes
  # API for accessing and building New Quizzes.
  #
  # **Note: This API is under active development and the endpoints listed here will
  # not function until the API is enabled.**
  class QuizzesApiController < ApplicationController
    before_action :require_feature_flag
    before_action :require_context

    # @API Get a new quiz
    # Get details about a single new quiz.
    #
    # @argument course_id [Required, Integer]
    #
    # @argument assignment_id [Required, Integer]
    #   The id of the assignment associated with the quiz.
    #
    # @example_request
    #   curl 'https://<canvas>/api/quiz/v1/courses/1/quizzes/12' \
    #         -H 'Authorization: Bearer <token>'
    def show
      assignment = api_find(@context.active_assignments, params[:assignment_id])
      return render_unauthorized_action unless assignment.grants_right?(@current_user, :read) && assignment.visible_to_user?(@current_user)

      log_api_asset_access(assignment, "assignments", assignment.assignment_group)

      render json: {}
    end

    # @API List quizzes
    # Get a list of quizzes.
    #
    # @example_request
    #   curl 'https://<canvas>/api/quiz/v1/courses/1/quizzes' \
    #        -H 'Authorization Bearer <token>'
    def index
      log_api_asset_access(["assignments", @context], "assignments", "other")

      render json: {}
    end

    private

    def require_feature_flag
      not_found unless Account.site_admin.feature_enabled?(:new_quiz_public_api)
    end
  end
end
